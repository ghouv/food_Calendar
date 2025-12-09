import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject var viewModel: TodayMealsViewModel

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.setLocalizedDateFormatFromTemplate("Md")
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                calorieSection
                macroSection
            }
            .padding()
        }
        .navigationTitle("통계")
    }

    private var calorieSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 7일 칼로리")
                .font(.headline)

            Chart(viewModel.last7DaysCalories()) { item in
                BarMark(
                    x: .value("날짜", dateFormatter.string(from: item.date)),
                    y: .value("칼로리", item.calories)
                )
                .foregroundStyle(.tint)
            }
            .chartYAxisLabel("kcal", position: .trailing)
            .frame(height: 220)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var macroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("오늘의 영양 비율")
                .font(.headline)

            let macroData = viewModel.macrosForSelectedDate()

            Chart(macroData) { item in
                SectorMark(
                    angle: .value("그램", item.grams),
                    innerRadius: .ratio(0.55),
                    angularInset: 1
                )
                .foregroundStyle(by: .value("영양소", item.name))
                .annotation(position: .overlay) {
                    if item.grams > 0 {
                        Text("\(item.grams)g")
                            .font(.caption2)
                            .foregroundColor(.primary)
                    }
                }
            }
            .frame(height: 260)
            .chartLegend(.visible)

            let total = viewModel.totalCalories(on: viewModel.selectedDate)
            Text("총 \(total) kcal")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    AnalyticsView(viewModel: TodayMealsViewModel(context: PersistenceController.shared.viewContext))
}
