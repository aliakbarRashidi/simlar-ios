source 'https://github.com/CocoaPods/Specs.git'
source 'https://gitlab.linphone.org/BC/public/podspec.git'

platform :ios, '9.1'
inhibit_all_warnings!

$PODFILE_PATH = 'liblinphone'

target 'Simlar' do
  use_frameworks!

  pod 'libPhoneNumber-iOS'
  pod 'CocoaLumberjack', '3.5.3'
  if File.exist?($PODFILE_PATH)
    pod 'linphone-sdk', :path => $PODFILE_PATH
  else
    pod 'linphone-sdk', '4.2'
  end

  target 'SimlarTests' do
    inherit! :search_paths
  end
end

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-Simlar/Pods-Simlar-acknowledgements.plist', 'Simlar/Settings.bundle/PodsAcknowledgements.plist', :remove_destination => true)
end
