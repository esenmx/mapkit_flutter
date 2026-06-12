import Flutter
import Foundation
import MapKit

extension MapKitViewHost {

    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation: FlutterAnnotation = view.annotation as? FlutterAnnotation {
            self.currentlySelectedAnnotation = annotation.id
            if !annotation.selectedProgrammatically {
                self.onAnnotationClick(annotation: annotation)
            } else {
                annotation.selectedProgrammatically = false
            }

            if annotation.calloutConsumesTapEvents {
                let tapGestureRecognizer = InfoWindowTapGestureRecognizer(target: self, action: #selector(onCalloutTapped))
                tapGestureRecognizer.annotationId = annotation.id
                tapGestureRecognizer.annotationView = view
                view.addGestureRecognizer(tapGestureRecognizer)
            }
        }
    }

    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        } else if let cluster = annotation as? MKClusterAnnotation {
            return self.getClusterAnnotationView(cluster: cluster)
        } else if let flutterAnnotation = annotation as? FlutterAnnotation {
            return self.getAnnotationView(annotation: flutterAnnotation)
        }
        return nil
    }

    private func getClusterAnnotationView(cluster: MKClusterAnnotation) -> MKAnnotationView {
        let id = "mapkit.cluster"
        self.mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: id)
        let view = self.mapView.dequeueReusableAnnotationView(withIdentifier: id, for: cluster) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: cluster, reuseIdentifier: id)
        view.markerTintColor = .systemBlue
        view.glyphText = "\(cluster.memberAnnotations.count)"
        view.canShowCallout = false
        return view
    }

    func getAnnotationView(annotation: FlutterAnnotation) -> MKAnnotationView {
        let identifier: String = annotation.id
        let dequeued = self.mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        let oldFlutterAnnotation = dequeued?.annotation as? FlutterAnnotation
        let view: MKAnnotationView
        if let dequeued, oldFlutterAnnotation?.icon.iconType == annotation.icon.iconType {
            view = dequeued
        } else if annotation.icon.isCustomImage {
            view = getCustomAnnotationView(annotation: annotation, id: identifier)
        } else {
            view = getMarkerAnnotationView(annotation: annotation, id: identifier)
        }
        view.annotation = annotation
        view.isHidden = annotation.isHidden
        view.zPriority = MKAnnotationViewZPriority(rawValue: Float(annotation.zPriority))
        if annotation.icon.isCustomImage {
            self.initInfoWindow(annotation: annotation, annotationView: view)
            // Native normalized anchor (`MKAnnotationView.anchorPoint`)
            // replaces the old manual centerOffset math.
            view.anchorPoint = annotation.anchorPoint
        }
        view.canShowCallout = true
        view.alpha = CGFloat(annotation.alpha)
        view.isDraggable = annotation.isDraggable
        view.clusteringIdentifier = annotation.clusteringIdentifier

        return view
    }

    func annotationsToAdd(_ annotations: [PlatformAnnotation]) {
        for annotation in annotations {
            addAnnotation(FlutterAnnotation(fromPlatform: annotation))
        }
    }

    func annotationsToChange(_ annotations: [PlatformAnnotation]) {
        let oldAnnotations: [MKAnnotation] = self.mapView.annotations
        for annotationData in annotations {
            if let annotationToChange = oldAnnotations.first(where: { ($0 as? FlutterAnnotation)?.id == annotationData.id }) as? FlutterAnnotation {
                let newAnnotation = FlutterAnnotation(fromPlatform: annotationData)
                if annotationToChange != newAnnotation {
                    if !annotationToChange.wasDragged {
                        updateAnnotation(annotation: newAnnotation)
                    } else {
                        annotationToChange.wasDragged = false
                    }
                }
            }
        }
    }

    func annotationsToRemove(_ annotationIds: [String]) {
        for annotationId in annotationIds {
            removeAnnotation(id: annotationId)
        }
    }

    func onAnnotationClick(annotation: MKAnnotation) {
        if let flutterAnnotation: FlutterAnnotation = annotation as? FlutterAnnotation {
            self.flutterApi.onAnnotationTap(annotationId: flutterAnnotation.id) { _ in }
        }
    }

    func selectAnnotation(with id: String) {
        if let annotation: FlutterAnnotation = self.getAnnotation(with: id) {
            annotation.selectedProgrammatically = true
            self.mapView.selectAnnotation(annotation, animated: true)
        }
    }

    func hideAnnotation(with id: String) {
        if let annotation: FlutterAnnotation = self.getAnnotation(with: id) {
            self.mapView.deselectAnnotation(annotation, animated: true)
        }
    }

    func isAnnotationSelected(with id: String) -> Bool {
        return self.mapView.selectedAnnotations.contains(where: { annotation in return self.getAnnotation(with: id) == (annotation as? FlutterAnnotation) })
    }

    private func removeAnnotation(id: String) {
        if let flutterAnnotation: FlutterAnnotation = self.getAnnotation(with: id) {
            self.mapView.removeAnnotation(flutterAnnotation)
        }
    }

    private func initInfoWindow(annotation: FlutterAnnotation, annotationView: MKAnnotationView) {
        let x = annotationView.frame.origin.x
            + annotationView.frame.width * annotation.anchorPoint.x
        annotationView.calloutOffset = CGPoint(x: x, y: 0)
        if let lines = annotation.subtitle?.split(whereSeparator: { $0.isNewline }) {
            let customCallout = UIStackView()
            customCallout.axis = .vertical
            customCallout.alignment = .fill
            customCallout.distribution = .fill
            for line in lines {
                let subtitle = UILabel()
                subtitle.text = String(line)
                customCallout.addArrangedSubview(subtitle)
            }
            annotationView.detailCalloutAccessoryView = customCallout
        }
    }

    @objc func onCalloutTapped(infoWindowTap: InfoWindowTapGestureRecognizer) {
        guard let annotationId = infoWindowTap.annotationId else { return }
        if self.currentlySelectedAnnotation == annotationId {
            self.flutterApi.onCalloutTap(annotationId: annotationId) { _ in }
        } else {
            infoWindowTap.annotationView?.removeGestureRecognizer(infoWindowTap)
        }
    }

    private func getAnnotation(with id: String) -> FlutterAnnotation? {
        return self.mapView.annotations.filter { annotation in return (annotation as? FlutterAnnotation)?.id == id }.first as? FlutterAnnotation
    }

    private func annotationExists(with id: String) -> Bool {
        return self.getAnnotation(with: id) != nil
    }

    /**
     Checks if an Annotation with the same id exists and removes it before adding if necessary
     - Parameter annotation: the FlutterAnnotation that should be added
     */
    private func addAnnotation(_ annotation: FlutterAnnotation) {
        if self.annotationExists(with: annotation.id) {
            self.removeAnnotation(id: annotation.id)
        }
        self.mapView.addAnnotation(annotation)
    }

    private func updateAnnotation(annotation: FlutterAnnotation) {
        guard let oldAnnotation = self.getAnnotation(with: annotation.id) else { return }
        // Only `coordinate` is KVO-observable on MKAnnotation; the rest are
        // plain properties whose assignment is synchronous regardless of an
        // animation block. Keep the animation block to a single property so
        // the bracketing reflects what actually animates.
        UIView.animate(withDuration: 0.32) {
            oldAnnotation.coordinate = annotation.coordinate
        }
        oldAnnotation.zPriority = annotation.zPriority
        oldAnnotation.anchorPoint = annotation.anchorPoint
        oldAnnotation.alpha = annotation.alpha
        oldAnnotation.isHidden = annotation.isHidden
        oldAnnotation.isDraggable = annotation.isDraggable
        oldAnnotation.title = annotation.title
        oldAnnotation.subtitle = annotation.subtitle
        oldAnnotation.clusteringIdentifier = annotation.clusteringIdentifier
        oldAnnotation.icon = annotation.icon

        // Re-apply the view-level properties the annotation view captured at
        // creation time.
        if let view = self.mapView.view(for: oldAnnotation) {
            view.alpha = CGFloat(annotation.alpha)
            view.isHidden = annotation.isHidden
            view.isDraggable = annotation.isDraggable
            view.zPriority = MKAnnotationViewZPriority(rawValue: Float(annotation.zPriority))
            if annotation.icon.isCustomImage {
                view.image = annotation.icon.image
                view.anchorPoint = annotation.anchorPoint
            }
        }
    }

    private func getMarkerAnnotationView(annotation: FlutterAnnotation, id: String) -> MKMarkerAnnotationView {
        self.mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: id)
        let markerAnnotationView = self.mapView.dequeueReusableAnnotationView(withIdentifier: id, for: annotation) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)

        if let tint = annotation.icon.markerTint {
            markerAnnotationView.markerTintColor = tint
        }
        if let glyphText = annotation.icon.glyphText {
            markerAnnotationView.glyphText = glyphText
        }
        if let glyphImage = annotation.icon.glyphImage {
            markerAnnotationView.glyphImage = glyphImage
        }
        if let glyphTint = annotation.icon.glyphTint {
            markerAnnotationView.glyphTintColor = glyphTint
        }

        return markerAnnotationView
    }

    private func getCustomAnnotationView(annotation: FlutterAnnotation, id: String) -> MKAnnotationView {
        self.mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: id)
        let annotationView = self.mapView.dequeueReusableAnnotationView(withIdentifier: id, for: annotation)
        annotationView.image = annotation.icon.image
        return annotationView
    }
}

class InfoWindowTapGestureRecognizer: UITapGestureRecognizer {
    var annotationView: UIView?
    var annotationId: String?
}
