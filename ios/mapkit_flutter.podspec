#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'mapkit_flutter'
  s.version          = '0.2.0'
  s.summary          = 'MapKit for Flutter.'
  s.description      = <<-DESC
Display MKMapView as a Flutter platform view on iOS,
with annotations, overlays, clustering, look-around, tile overlays, and modern
MapKit configurations (iOS 17+).
                       DESC
  s.homepage         = 'https://github.com/esenmx/mapkit_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Mehmet Esen' => 'mehmetesen@proton.me' }
  s.source           = { :path => '.' }
  s.source_files = 'mapkit_flutter/Sources/mapkit_flutter/**/*.swift'
  s.dependency 'Flutter'
  s.frameworks = 'MapKit', 'CoreLocation'

  s.ios.deployment_target = '17.0'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_VERSION' => '5.0',
  }
end
