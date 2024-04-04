#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'device_calendar'
  s.version          = '0.0.1'
  s.summary          = 'Cross Platform plugin to modify calendars'
  s.description      = <<-DESC
  A cross platform plugin for modifying calendars on the user's device
                       DESC
  s.homepage         = 'https://github.com/builttoroam/device_calendar'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Built to Roam' => 'info@builttoroam.com' }
  s.source           = { :path => '.' }
  s.swift_version = '5.0'
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  
  s.ios.deployment_target = '8.0'
  s.resource_bundles = {'device_calendar' => ['Resources/PrivacyInfo.xcprivacy']}
end

