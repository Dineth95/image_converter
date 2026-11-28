#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint image_converter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'image_converter'
  s.version          = '0.1.0'
  s.summary          = 'Convert images to PDF and render PDF pages to images using native APIs.'
  s.description      = <<-DESC
Convert images to PDF and render PDF pages to images using native APIs.
                       DESC
  s.homepage         = 'https://github.com/Dineth95/image_converter'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Dineth Prabashwara' => 'prabshwaradineth@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'image_converter/Sources/image_converter/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'image_converter_privacy' => ['image_converter/Sources/image_converter/PrivacyInfo.xcprivacy']}
end
