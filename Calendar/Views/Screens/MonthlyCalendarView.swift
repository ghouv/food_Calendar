import SwiftUI

struct MonthlyCalendarView: View {
    @ObservedObject var viewModel: TodayMealsViewModel

    @State private var displayedMonth: Date

    private let calendar = Calendar.current
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }()
    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    init(viewModel: TodayMealsViewModel) {
        self.viewModel = viewModel
        let components = Calendar.current.dateComponents([.year, .month], from: viewModel.selectedDate)
        _displayedMonth = State(initialValue: Calendar.current.date(from: components) ?? Date())
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            weekdayHeader
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 12) {
                ForEach(daysInMonth(), id: \.self) { date in
                    dayCell(for: date)
                }
            }
            Spacer()
        }
        .padding()
        .navigationTitle("월간 캘린더")
    }

    private var header: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Text("◀")
            }
            Spacer()
            Text(monthFormatter.string(from: displayedMonth))
                .font(.headline)
            Spacer()
            Button(action: { changeMonth(by: 1) }) {
                Text("▶")
            }
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(weekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func daysInMonth() -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let prefixDays = (firstWeekday + 6) % 7 // shift so Sunday=0
        let totalSlots = prefixDays + range.count

        return (0..<totalSlots).compactMap { index in
            if index < prefixDays { return nil }
            return calendar.date(byAdding: .day, value: index - prefixDays, to: monthStart)
        }
    }

    private func dayCell(for date: Date?) -> some View {
        Group {
            if let date {
                let isToday = calendar.isDateInToday(date)
                let isSelected = calendar.isDate(date, inSameDayAs: viewModel.selectedDate)
                let calories = viewModel.totalCalories(on: date)

                VStack(spacing: 6) {
                    Text("\(calendar.component(.day, from: date))")
                        .fontWeight(isSelected ? .bold : .regular)
                        .padding(6)
                        .background(
                            Circle()
                                .strokeBorder(isToday ? Color.accentColor : Color.clear, lineWidth: 1)
                                .background(
                                    Circle()
                                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
                                )
                        )
                        .clipShape(Circle())

                    Text("\(calories) kcal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(4)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.selectedDate = date
                }
            } else {
                Color.clear
            }
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
}

#Preview {
    MonthlyCalendarView(viewModel: TodayMealsViewModel(context: PersistenceController.shared.viewContext))
}
