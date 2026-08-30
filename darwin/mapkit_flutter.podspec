#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'mapkit_flutter'
  s.version          = '0.3.7'
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
  s.source_files = 'mapkit_flutter/Sources/mapkit_flutter/**/*.swift'
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.frameworks = 'MapKit', 'CoreLocation'

  s.ios.deployment_target = '17.0'
  s.osx.deployment_target = '14.0'
  # Swift 6 language mode: data-race safety enforced by the compiler, not a
  # flag stack (subsumes the old -strict-concurrency=complete). Needs
  # Xcode 16+, already below Flutter's own minimum.
  s.swift_version = '6.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_VERSION' => '6.0',
    'OTHER_SWIFT_FLAGS' => '-warnings-as-errors'
  }
end
