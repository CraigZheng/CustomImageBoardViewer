# Uncomment this line to define a global platform for your project
platform :ios, '15.0'
# Uncomment this line if you're using Swift
use_frameworks!

target 'CustomImageBoardViewer' do
pod "MWPhotoBrowser", :git => 'https://github.com/CraigZheng/MWPhotoBrowser.git', :branch => 'master'
pod 'iOS-Slide-Menu', :git => 'https://github.com/CraigZheng/iOS-Slide-Menu.git', :branch => 'master'
pod 'PureLayout'
pod 'CocoaLumberjack'
pod 'AFNetworking', '~> 3.0'
pod 'SplunkMint'
pod 'SwiftMessages', :git => 'https://github.com/SwiftKickMobile/SwiftMessages.git', :branch => 'work/swift5'
pod 'DZNEmptyDataSet'
pod 'TTTAttributedLabel'
end

target 'CustomImageBoardViewerTests' do
pod 'CocoaLumberjack'
pod 'iOS-Slide-Menu', :git => 'https://github.com/CraigZheng/iOS-Slide-Menu.git', :branch => 'master'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Xcode 26 supports iOS 15.0+ deployment targets only.
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 15.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
      # SplunkMint is a prebuilt static framework whose arm64 slice is device-only,
      # so simulator builds must be x86_64 (keep in sync with the app project).
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end

  # AFNetworking 3.x imports <netinet6/in6.h>, a private header that modern
  # SDKs reject ("Use of private header from outside its module").
  # <netinet/in.h> already provides everything it needs.
  Dir.glob(File.join(installer.sandbox.root, 'AFNetworking', '**', '*.{h,m}')).each do |path|
    contents = File.read(path)
    next unless contents =~ /^#import <netinet6\/in6\.h>/
    File.chmod(0644, path)
    File.write(path, contents.gsub(/^#import <netinet6\/in6\.h>/, '// #import <netinet6/in6.h> (removed: private header, breaks Xcode 26 builds)'))
  end
end
