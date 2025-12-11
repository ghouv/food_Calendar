import SwiftUI
import Charts

struct AnalyticsView: View {
    enum AnalyticsRange: String, CaseIterable {
        case week = "주간"
        case month = "월간"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            }
        }
    }

    @ObservedObject var viewModel: TodayMealsViewModel
    @State private var selectedRange: AnalyticsRange = .week

    private var summaries: [TodayMealsViewModel.DailySummary] {
        viewModel.dailySummaries(forLast: selectedRange.days)
    }

    private var averageCalories: Int {
        guard !summaries.isEmpty else { return 0 }
        let total = viewModel.totalCalories(in: summaries)
        return total / summaries.count
    }

    private var macroTotals: (carbs: Int, protein: Int, fat: Int) {
        viewModel.macroTotals(in: summaries)
    }

    private var calorieGoalProgress: Double {
        guard !summaries.isEmpty else { return 0 }
        let total = Double(viewModel.totalCalories(in: summaries))
        let target = Double(viewModel.targetCaloriesPerDay * summaries.count)
        guard target > 0 else { return 0 }
        return min(total / target, 1.0)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("기간", selection: $selectedRange) {
                    ForEach(AnalyticsRange.allCases, id: \.self) { range in
                        Text(range.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("칼로리 추이")
                        .font(.headline)

                    if summaries.isEmpty {
                        Text("아직 기록된 식단이 없습니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Chart(summaries) { item in
                            LineMark(
                                x: .value("날짜", item.date, unit: .day),
                                y: .value("칼로리", item.totalCalories)
                            )
                            .interpolationMethod(.catmullRom)
                            .symbol(Circle())
                            .foregroundStyle(.blue)
                        }
                        .frame(height: 200)
                    }

                    Text("평균 \(averageCalories) kcal / 일")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("영양 비율")
                        .font(.headline)

                    if summaries.isEmpty {
                        Text("영양 정보를 볼 수 있는 식단이 없습니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        let macroData: [(name: String, grams: Int)] = [
                            ("탄수화물", macroTotals.carbs),
                            ("단백질", macroTotals.protein),
                            ("지방", macroTotals.fat)
                        ]

                        Chart(macroData, id: \.name) { item in
                            BarMark(
                                x: .value("g", item.grams),
                                y: .value("영양소", item.name)
                            )
                            .foregroundStyle(.orange)
                        }
                        .frame(height: 160)

                        HStack {
                            Text("탄수화물 \(macroTotals.carbs)g")
                            Spacer()
                            Text("단백질 \(macroTotals.protein)g")
                            Spacer()
                            Text("지방 \(macroTotals.fat)g")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("목표 대비 진척도")
                        .font(.headline)

                    let percent = Int(calorieGoalProgress * 100)

                    ProgressView(value: calorieGoalProgress)
                        .progressViewStyle(.linear)
                        .tint(.blue)

                    Text("목표 대비 \(percent)% 달성")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .padding(.horizontal)

                Spacer(minLength: 16)
            }
            .padding(.top)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("통계")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AnalyticsView(viewModel: TodayMealsViewModel(context: PersistenceController.shared.viewContext))
}
