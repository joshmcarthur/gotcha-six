import SwiftUI

/// Asset-catalog SVG (preserves vector data). Names match Teaching*.imageset.
struct TeachingImage: View {
    let name: String

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityHidden(false)
    }
}
