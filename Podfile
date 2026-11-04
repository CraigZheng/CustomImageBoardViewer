# Uncomment this line to define a global platform for your project
platform :ios, '15.0'
# Uncomment this line if you're using Swift
use_frameworks!

target 'CustomImageBoardViewer' do
pod "MWPhotoBrowser", :git => 'https://github.com/CraigZheng/MWPhotoBrowser.git', :branch => 'master'
pod 'iOS-Slide-Menu', :git => 'https://github.com/CraigZheng/iOS-Slide-Menu.git', :branch => 'master'
pod 'PureLayout'
pod 'CocoaLumberjack'
pod 'SwiftMessages', :git => 'https://github.com/SwiftKickMobile/SwiftMessages.git', :branch => 'work/swift5'
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
      # Keep simulator build settings in sync with the app project.
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
