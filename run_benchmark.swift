import Foundation

struct PlatformAnnotation {
    let id: String
}

class FlutterAnnotation {
    let id: String
    var wasDragged = false

    init(id: String) {
        self.id = id
    }
}

class MapView {
    var annotations: [Any] = []
}

class System {
    var mapView = MapView()

    func oldAnnotationsToChange(_ annotations: [PlatformAnnotation]) {
        let oldAnnotations: [Any] = self.mapView.annotations
        for annotationData in annotations {
            if let annotationToChange = oldAnnotations.first(where: { ($0 as? FlutterAnnotation)?.id == annotationData.id }) as? FlutterAnnotation {
                // simulate some work
            }
        }
    }

    func newAnnotationsToChange(_ annotations: [PlatformAnnotation]) {
        let oldAnnotations: [Any] = self.mapView.annotations

        // Build a dictionary of existing annotations by ID
        var oldAnnotationsDict = [String: FlutterAnnotation]()
        for annotation in oldAnnotations {
            if let flutterAnnotation = annotation as? FlutterAnnotation {
                oldAnnotationsDict[flutterAnnotation.id] = flutterAnnotation
            }
        }

        for annotationData in annotations {
            if let annotationToChange = oldAnnotationsDict[annotationData.id] {
                // simulate some work
            }
        }
    }
}

let system = System()
for i in 0..<10000 {
    system.mapView.annotations.append(FlutterAnnotation(id: "id_\(i)"))
}

var platformAnnotations: [PlatformAnnotation] = []
for i in 0..<10000 {
    platformAnnotations.append(PlatformAnnotation(id: "id_\(i)"))
}

let startOld = CFAbsoluteTimeGetCurrent()
system.oldAnnotationsToChange(platformAnnotations)
let endOld = CFAbsoluteTimeGetCurrent()
print("Old O(n^2) approach took \(endOld - startOld) seconds")

let startNew = CFAbsoluteTimeGetCurrent()
system.newAnnotationsToChange(platformAnnotations)
let endNew = CFAbsoluteTimeGetCurrent()
print("New O(n) approach took \(endNew - startNew) seconds")
