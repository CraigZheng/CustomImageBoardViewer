//
//  PhotoBrowserViewController.swift
//  CustomImageBoardViewer
//
//  Lightweight replacement for MWPhotoBrowser: swipe between local/remote
//  images with pinch-zoom and a share action.
//

import UIKit

@objc class PhotoBrowserViewController: UIViewController {
    @objc private(set) var currentIndex: Int = 0
    @objc var onActionButton: ((Int) -> Void)?

    private let sources: [Any]
    private var pageViewController: UIPageViewController!
    private var hideControlsWorkItem: DispatchWorkItem?

    @objc init(sources: [Any], startIndex: Int) {
        self.sources = sources
        self.currentIndex = max(0, min(startIndex, max(sources.count - 1, 0)))
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        // Avoid iOS 26 zero-width ButtonWrapper conflicts from system bar button items.
        let actionButton = UIButton(type: .system)
        actionButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        actionButton.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: actionButton)

        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [.interPageSpacing: 16]
        )
        pageViewController.dataSource = self
        pageViewController.delegate = self
        addChild(pageViewController)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageViewController.view)
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        pageViewController.didMove(toParent: self)

        if let page = page(for: currentIndex) {
            pageViewController.setViewControllers([page], direction: .forward, animated: false)
        }
        updateTitle()
        scheduleHideControls()
    }

    @objc func setCurrentPhotoIndex(_ index: Int) {
        guard sources.indices.contains(index) else { return }
        let direction: UIPageViewController.NavigationDirection = index >= currentIndex ? .forward : .reverse
        currentIndex = index
        if let page = page(for: index) {
            pageViewController?.setViewControllers([page], direction: direction, animated: false)
        }
        updateTitle()
    }

    private func page(for index: Int) -> ZoomableImageViewController? {
        guard sources.indices.contains(index) else { return nil }
        let page = ZoomableImageViewController(source: sources[index], index: index)
        page.onSingleTap = { [weak self] in
            self?.toggleControls()
        }
        return page
    }

    private func updateTitle() {
        guard !sources.isEmpty else {
            title = nil
            return
        }
        title = "\(currentIndex + 1) / \(sources.count)"
    }

    @objc private func actionTapped() {
        onActionButton?(currentIndex)
    }

    private func toggleControls() {
        let hidden = navigationController?.isNavigationBarHidden == false
        navigationController?.setNavigationBarHidden(hidden, animated: true)
        if !hidden {
            scheduleHideControls()
        } else {
            hideControlsWorkItem?.cancel()
        }
    }

    private func scheduleHideControls() {
        hideControlsWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.navigationController?.setNavigationBarHidden(true, animated: true)
        }
        hideControlsWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: work)
    }
}

extension PhotoBrowserViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let current = viewController as? ZoomableImageViewController else { return nil }
        return page(for: current.index - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let current = viewController as? ZoomableImageViewController else { return nil }
        return page(for: current.index + 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
              let visible = pageViewController.viewControllers?.first as? ZoomableImageViewController else { return }
        currentIndex = visible.index
        updateTitle()
        scheduleHideControls()
    }
}

private final class ZoomableImageViewController: UIViewController, UIScrollViewDelegate {
    let index: Int
    private let source: Any
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    var onSingleTap: (() -> Void)?

    init(source: Any, index: Int) {
        self.source = source
        self.index = index
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTap.require(toFail: doubleTap)
        scrollView.addGestureRecognizer(singleTap)

        loadImage()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutImage()
    }

    private func loadImage() {
        if let image = source as? UIImage {
            imageView.image = image
            layoutImage()
            return
        }

        let url: URL?
        if let value = source as? URL {
            url = value
        } else if let path = source as? String {
            url = URL(fileURLWithPath: path)
        } else if let path = source as? NSString {
            url = URL(fileURLWithPath: path as String)
        } else {
            url = nil
        }

        guard let url else { return }
        if url.isFileURL {
            imageView.image = UIImage(contentsOfFile: url.path)
            layoutImage()
        } else {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.imageView.image = image
                    self?.layoutImage()
                }
            }.resume()
        }
    }

    private func layoutImage() {
        guard let image = imageView.image else { return }
        let boundsSize = scrollView.bounds.size
        guard boundsSize.width > 0, boundsSize.height > 0 else { return }

        let widthScale = boundsSize.width / image.size.width
        let heightScale = boundsSize.height / image.size.height
        let minScale = min(widthScale, heightScale)
        let fittedSize = CGSize(width: image.size.width * minScale, height: image.size.height * minScale)
        imageView.frame = CGRect(origin: .zero, size: fittedSize)
        scrollView.contentSize = fittedSize
        scrollView.zoomScale = 1
        centerImage()
    }

    private func centerImage() {
        let boundsSize = scrollView.bounds.size
        var frame = imageView.frame
        frame.origin.x = frame.size.width < boundsSize.width ? (boundsSize.width - frame.size.width) / 2 : 0
        frame.origin.y = frame.size.height < boundsSize.height ? (boundsSize.height - frame.size.height) / 2 : 0
        imageView.frame = frame
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            let zoomRect = CGRect(
                x: point.x - 50,
                y: point.y - 50,
                width: 100,
                height: 100
            )
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }

    @objc private func handleSingleTap() {
        onSingleTap?()
    }
}
