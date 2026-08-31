import SwiftUI
import MobAIPreview

// Preview adapter for the application-facing MapKit snapshot surface. It reads
// the current mocked location and renders a stable labelled placeholder.
//
// The place is read in a default argument rather than inside body, so that a
// re-render carries the current world in. A view with no stored properties
// never changes value, so the graph would keep the first answer forever.
public struct MapSnapshot: View {
    private let place: String

    public init(place: String = MapSnapshot.currentPlaceName()) {
        self.place = place
    }

    public static func currentPlaceName() -> String {
        location.current()?.label ?? "nowhere"
    }

    public var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.82, green: 0.86, blue: 0.80))
                .frame(height: 120.0)
            Text("map of \(place)")
        }
    }
}
