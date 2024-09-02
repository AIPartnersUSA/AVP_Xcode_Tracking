import Foundation
import RealityKit
import ARKit

@objc class ObjectTrackingBridge: NSObject {

    private static var trackingProvider: ObjectTrackingProvider?
    private static var arkitSession = ARKitSession()

    // Start tracking and return a Boolean indicating success
    @objc static func startTracking() -> Bool {
        let referenceObjects = AppState.shared.referenceObjectLoader.enabledReferenceObjects
        guard !referenceObjects.isEmpty else {
            print("No reference objects available for tracking.")
            return false
        }

        trackingProvider = ObjectTrackingProvider(referenceObjects: referenceObjects)
        do {
            try arkitSession.run([trackingProvider!])
            return true
        } catch {
            print("Failed to start tracking: \(error)")
            return false
        }
    }

    // Stop tracking and clean up resources
    @objc static func stopTracking() {
        arkitSession.stop()
        trackingProvider = nil
    }

    // Retrieve the transform of the tracked object as an array of Floats [x, y, z]
    @objc static func getTrackedObjectTransform() -> [Float] {
        guard let anchor = trackingProvider?.trackedAnchor else {
            return [0.0, 0.0, 0.0]
        }
        let transform = anchor.transform.columns.3
        return [transform.x, transform.y, transform.z]
    }

    // Add a new reference object from a specified URL
    @objc static func addReferenceObject(url: String) -> Bool {
        guard let objectURL = URL(string: url) else { return false }
        Task {
            await AppState.shared.referenceObjectLoader.addReferenceObject(objectURL)
        }
        return true
    }

    // Remove an existing reference object by its identifier
    @objc static func removeReferenceObject(id: UUID) {
        if let object = AppState.shared.referenceObjectLoader.referenceObjects.first(where: { $0.id == id }) {
            AppState.shared.referenceObjectLoader.removeObject(object)
        }
    }

    // Check if tracking is currently active
    @objc static func isTrackingActive() -> Bool {
        return trackingProvider != nil
    }
}
