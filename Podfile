# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'
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
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 12.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      end
    end
  end
end