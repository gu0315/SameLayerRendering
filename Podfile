source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target 'SameLayerRendering' do
    pod 'SnapKit', '~> 5.6.0'
    pod 'ZFPlayer'
    pod 'ZFPlayer/ControlView'
    pod 'ZFPlayer/AVPlayer'
    pod 'KTVHTTPCache'
    pod 'SDWebImage'
    pod 'LookinServer', :configurations => ['Debug']
    pod 'IQKeyboardManagerSwift'
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
  end
end

