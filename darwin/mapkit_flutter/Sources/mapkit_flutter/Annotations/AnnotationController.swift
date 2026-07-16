import Foundation
import MapKit

#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import AppKit
import FlutterMacOS
#endif

extension MapKitViewHost {

    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation: FlutterAnnotation = view.annotation as? FlutterAnnotation {
            self.currentlySelectedAnnotation = annotation.id
            if !annotation.selectedProgrammatically {
                self.onAnnotationClick(annotation: annotation)
            } else {
                annotation.selectedProgrammatically = false
            }

            #if os(iOS)
            // Callout tap forwarding is bridged via a tap recognizer on iOS;
            // the macOS callout uses MapKit's default behavior.
            if annotation.calloutConsumesTapEvents {
                let tapGestureRecognizer = InfoWindowTapGestureRecognizer(target: self, action: #selector(onCalloutTapped))
                tapGestureRecognizer.annotationId = annotation.id
                tapGestureRecognizer.annotationView = view
                view.addGestureRecognizer(tapGestureRecognizer)
            }
            #endif
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
        let view: MKAnnotationView
        if annotation.icon.isCustomImage {
            let customView = self.mapView.dequeueReusableAnnotationView(withIdentifier: "FlutterCustomAnnotationView", for: annotation)
            customView.image = annotation.icon.image
            self.initInfoWindow(annotation: annotation, annotationView: customView)
            #if os(iOS)
            // Native normalized anchor (`MKAnnotationView.anchorPoint`,
            // iOS-only) replaces the old manual centerOffset math. macOS
            // centers the image on the coordinate by default.
            customView.anchorPoint = annotation.anchorPoint
            #endif
            view = customView
        } else {
            let markerView = self.mapView.dequeueReusableAnnotationView(withIdentifier: "FlutterMarkerAnnotationView", for: annotation) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "FlutterMarkerAnnotationView")
            self.applyMarkerStyle(markerView, annotation.icon)
            view = markerView
        }
        view.annotation = annotation
        view.isHidden = annotation.isHidden
        view.zPriority = MKAnnotationViewZPriority(rawValue: Float(annotation.zPriority))
        view.canShowCallout = true
        view.platformAlpha = CGFloat(annotation.alpha)
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
        for annotationData in annotations {
            if let annotationToChange = self.getAnnotation(with: annotationData.id) {
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
        return self.mapView.selectedAnnotations.contains(where: { annotation in return (annotation as? FlutterAnnotation)?.id == id })
    }

    private func removeAnnotation(id: String) {
        if let flutterAnnotation: FlutterAnnotation = self.getAnnotation(with: id) {
            self.annotationsById.removeValue(forKey: id)
            self.mapView.removeAnnotation(flutterAnnotation)
        }
    }

    private func initInfoWindow(annotation: FlutterAnnotation, annotationView: MKAnnotationView) {
        let x = annotationView.frame.origin.x
            + annotationView.frame.width * annotation.anchorPoint.x
        annotationView.calloutOffset = CGPoint(x: x, y: 0)
        #if os(iOS)
        // The multi-line subtitle accessory is built with UIKit; macOS uses
        // MapKit's default callout (title/subtitle).
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
        } else {
            // Clear a stale accessory when the subtitle is removed on update.
            annotationView.detailCalloutAccessoryView = nil
        }
        #endif
    }

    #if os(iOS)
    @objc func onCalloutTapped(infoWindowTap: InfoWindowTapGestureRecognizer) {
        guard let annotationId = infoWindowTap.annotationId else { return }
        if self.currentlySelectedAnnotation == annotationId {
            self.flutterApi.onCalloutTap(annotationId: annotationId) { _ in }
        } else {
            infoWindowTap.annotationView?.removeGestureRecognizer(infoWindowTap)
        }
    }
    #endif

    private func getAnnotation(with id: String) -> FlutterAnnotation? {
        return self.annotationsById[id]
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
        self.annotationsById[annotation.id] = annotation
        self.mapView.addAnnotation(annotation)
    }

    private func updateAnnotation(annotation: FlutterAnnotation) {
        guard let oldAnnotation = self.getAnnotation(with: annotation.id) else { return }
        // A change of icon variant (system marker <-> custom image) needs a
        // different annotation-view class, which an in-place update can't swap.
        // Replace the annotation so the delegate builds a fresh view of the
        // correct kind instead of forcing an image onto a marker view.
        if oldAnnotation.icon.iconType != annotation.icon.iconType {
            let isSelected = self.isAnnotationSelected(with: annotation.id)
            self.removeAnnotation(id: annotation.id)
            self.addAnnotation(annotation)
            if isSelected {
                self.selectAnnotation(with: annotation.id)
            }
            return
        }
        // Only `coordinate` is KVO-observable on MKAnnotation; the rest are
        // plain properties whose assignment is synchronous regardless of an
        // animation block. Keep the animation block to a single property so
        // the bracketing reflects what actually animates.
        #if os(iOS)
        UIView.animate(withDuration: 0.32) {
            oldAnnotation.coordinate = annotation.coordinate
        }
        #elseif os(macOS)
        oldAnnotation.coordinate = annotation.coordinate
        #endif
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
            view.platformAlpha = CGFloat(annotation.alpha)
            view.isHidden = annotation.isHidden
            view.isDraggable = annotation.isDraggable
            view.zPriority = MKAnnotationViewZPriority(rawValue: Float(annotation.zPriority))
            view.clusteringIdentifier = annotation.clusteringIdentifier
            if annotation.icon.isCustomImage {
                view.image = annotation.icon.image
                #if os(iOS)
                view.anchorPoint = annotation.anchorPoint
                #endif
            }
            switch view {
            case let marker as MKMarkerAnnotationView:
                self.applyMarkerStyle(marker, annotation.icon)
            default:
                // The backing FlutterAnnotation could have swapped custom <-> marker;
                // we have to re-initialize the view's window so the old state
                // isn't left stale on the live view.
                self.initInfoWindow(annotation: annotation, annotationView: view)
            }
        }
    }

    /// Applies marker styling to `view`, assigning each property directly —
    /// including `nil` — so a value cleared between updates resets to MapKit's
    /// default (`markerTintColor = nil` → system red, `glyphTintColor = nil` →
    /// white). Shared by the create, reuse, and in-place-update paths so they
    /// cannot drift.
    private func applyMarkerStyle(_ view: MKMarkerAnnotationView, _ icon: AnnotationIcon) {
        view.markerTintColor = icon.markerTint
        view.glyphText = icon.glyphText
        view.glyphImage = icon.glyphImage
        view.glyphTintColor = icon.glyphTint
    }

}

#if os(iOS)
class InfoWindowTapGestureRecognizer: UITapGestureRecognizer {
    var annotationView: UIView?
    var annotationId: String?
}
#endif
