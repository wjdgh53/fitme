import SwiftUI
import UIKit

struct AvatarImageView<Placeholder: View>: View {
    let imageData: Data?
    let imageURL: URL?
    let size: CGFloat
    let cornerRadius: CGFloat
    let placeholder: () -> Placeholder

    init(
        imageData: Data?,
        imageURL: URL?,
        size: CGFloat,
        cornerRadius: CGFloat,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.imageData = imageData
        self.imageURL = imageURL
        self.size = size
        self.cornerRadius = cornerRadius
        self.placeholder = placeholder
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        Group {
            if let imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let imageURL {
                AsyncImage(url: imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholder()
                }
            } else {
                placeholder()
            }
        }
        .frame(width: size, height: size)
        .clipShape(shape)
    }
}
