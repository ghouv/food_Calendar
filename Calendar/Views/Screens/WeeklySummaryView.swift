import SwiftUI

struct WeeklySummaryView: View {
    @ObservedObject var viewModel: TodayMealsViewModel
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter
    }()

    private var weekDates: [Date] {
        viewModel.weekDates(for: viewModel.selectedDate)
    }

    var body: some View {
        List {
            ForEach(weekDates, id: \.self) { date in
                HStack {
                    Text(dateFormatter.string(from: date))
                        .fontWeight(calendar.isDate(date, inSameDayAs: viewModel.selectedDate) ? .bold : .regular)
                    Spacer()
                    Text("\(viewModel.totalCalories(on: date)) kcal")
                        .foregroundColor(calendar.isDate(date, inSameDayAs: viewModel.selectedDate) ? .accentColor : .secondary)
                }
            }
        }
        .navigationTitle("주간 요약")
    }
}

#Preview {
    WeeklySummaryView(viewModel: TodayMealsViewModel(context: PersistenceController.shared.viewContext))
}
