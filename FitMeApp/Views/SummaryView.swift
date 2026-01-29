import SwiftUI

struct SummaryView: View {
    let viewModel: SummaryViewModel

    var body: some View {
        HistoryDetailView(viewModel: HistoryDetailViewModel(
            data: MockDataProvider.historyDetail,
            onBack: viewModel.onFinish,
            onHome: viewModel.onFinish,
            onShare: {}
        ))
    }
}
