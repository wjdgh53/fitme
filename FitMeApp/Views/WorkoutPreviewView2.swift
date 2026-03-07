import SwiftUI

struct WorkoutPreviewView2: View {
    @ObservedObject var viewModel: WorkoutPreviewViewModel

    var body: some View {
        WorkoutPreviewStyledScreen(
            data: viewModel.data,
            onBack: viewModel.onBack,
            onMore: viewModel.onMore,
            onStart: viewModel.onStart,
            showLoading: false
        )
    }
}
