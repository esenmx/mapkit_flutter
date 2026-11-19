#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'mapkit_flutter'
  s.version          = '0.5.1'
  s.summary          = 'MapKit for Flutter.'
  s.description      = <<-DESC
Display MKMapView as a Flutter platform view on iOS and macOS,
with annotations, overlays, clustering, look-around (iOS only), tile overlays,
and modern MapKit configurations.
                       DESC
  s.homepage         = 'https://github.com/esenmx/mapkit_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Mehmet Esen' => 'mehmetesen@proton.me' }
  s.source           = { :path => '.' }
  s.source_files = 'mapkit_flutter/Sources/**/*.{swift,m,h}'
  # Keep the swiftgen-emitted header out of the pod's umbrella header so its
  # MAPKIT_FLUTTER_SWIFT_H include guard does not shadow mapkit_flutter-Swift.h.
  s.private_header_files = 'mapkit_flutter/Sources/mapkit_flutter_objc_gen/mapkit_flutter.h'
  s.resource_bundles = {'mapkit_flutter_privacy' => ['mapkit_flutter/Sources/mapkit_flutter/PrivacyInfo.xcprivacy']}
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.frameworks = 'MapKit', 'CoreLocation'

  s.ios.deployment_target = '17.0'
  s.osx.deployment_target = '14.0'
  # Swift 5 language mode until upstream Pigeon annotates the mutable static
  # globals its `useFfi: true` Swift generator emits.
  s.swift_version = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_VERSION' => '5.0'
  }
end
