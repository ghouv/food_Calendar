import SwiftUI
import CoreData

@MainActor
struct TodayMealsView: View {
    @StateObject private var viewModel: TodayMealsViewModel
    private let nutritionService = NutritionAIService()
    @State private var isPresentingAdd = false
    @State private var searchText: String = ""
    @State private var name = ""
    @State private var calories: Int? = nil
    @State private var carbs: Int? = nil
    @State private var protein: Int? = nil
    @State private var fat: Int? = nil
    @State private var isLoadingAI = false
    @State private var aiErrorMessage: String? = nil

    @State private var selectedMealForDetail: MealEntity? = nil

    init(viewModel: TodayMealsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    init(context: NSManagedObjectContext, date: Date = Date()) {
        _viewModel = StateObject(wrappedValue: TodayMealsViewModel(context: context, date: date))
    }

    private var formattedDate: String {
        viewModel.selectedDate.formatted(.dateTime.month().day().weekday(.abbreviated)).replacingOccurrences(of: ",", with: "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                topTabBar
                mealsList
            }
            .searchable(text: $searchText, prompt: "식단 이름 검색")
            .onChange(of: searchText, perform: handleSearchChange)
            .navigationTitle("식단 캘린더")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAdd) {
                addMealSheet
            }
            .sheet(item: $selectedMealForDetail) { meal in
                MealDetailView(viewModel: viewModel, meal: meal)
            }
        }
    }

    private var topTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                NavigationLink("주간 요약") {
                    WeeklySummaryView(viewModel: viewModel)
                }
                NavigationLink("월간 보기") {
                    MonthlyCalendarView(viewModel: viewModel)
                }
                NavigationLink("통계") {
                    AnalyticsView(viewModel: viewModel)
                }
                NavigationLink("즐겨찾기") {
                    FavoritesView(viewModel: viewModel)
                }
            }
            .padding(.horizontal)
        }
    }

    private var mealsList: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    dateHeader
                    summaryCard
                }
                .listRowInsets(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
            }

            Section("오늘의 식사") {
                ForEach(viewModel.filteredMealsForSelectedDate, id: \.objectID) { meal in
                    mealRow(meal)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedMealForDetail = meal
                        }
                }
                .onDelete(perform: viewModel.deleteMeals(at:))
            }
        }
        .listStyle(.insetGrouped)
    }

    private var addMealSheet: some View {
        NavigationStack {
            Form {
                Section("이름") {
                    TextField("예: 닭가슴살 샐러드", text: $name)
                }
                Section {
                    Button {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        isLoadingAI = true
                        aiErrorMessage = nil

                        nutritionService.fetchNutrition(for: name) { result in
                            isLoadingAI = false
                            switch result {
                            case .success(let info):
                                calories = info.calories
                                carbs = info.carbs
                                protein = info.protein
                                fat = info.fat
                            case .failure(let error):
                                aiErrorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isLoadingAI {
                                ProgressView()
                            }
                            Text("AI로 영양성분 자동 채우기")
                                .font(.callout)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(isLoadingAI)

                    if let aiErrorMessage {
                        Text(aiErrorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                Section("영양 정보") {
                    TextField("칼로리", value: $calories, format: .number)
                        .keyboardType(.numberPad)
                    TextField("탄수화물 (g)", value: $carbs, format: .number)
                        .keyboardType(.numberPad)
                    TextField("단백질 (g)", value: $protein, format: .number)
                        .keyboardType(.numberPad)
                    TextField("지방 (g)", value: $fat, format: .number)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("식사 추가")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        resetForm()
                        isPresentingAdd = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveMeal()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var dateHeader: some View {
        HStack {
            Button {
                viewModel.changeSelectedDate(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Spacer()

            Text(formattedDate)
                .font(.headline)

            Spacer()

            Button {
                viewModel.changeSelectedDate(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("총 칼로리")
                Spacer()
                Text("\(viewModel.totalCalories) kcal")
                    .fontWeight(.semibold)
            }
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Divider()
            HStack(spacing: 16) {
                macroPill(label: "탄수화물", value: viewModel.totalCarbs, unit: "g", color: .orange)
                macroPill(label: "단백질", value: viewModel.totalProtein, unit: "g", color: .green)
                macroPill(label: "지방", value: viewModel.totalFat, unit: "g", color: .blue)
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("목표: \(viewModel.goalCalories) kcal")
                    .font(.caption)

                ProgressView(value: viewModel.dailyProgress)
                    .tint(.blue)

                Text("진척도: \((viewModel.dailyProgress * 100).rounded())%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func macroPill(label: String, value: Int, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(value) \(unit)")
                .font(.headline)
                .foregroundColor(color)
        }
    }

    private func mealRow(_ meal: MealEntity) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(meal.name ?? "")
                    .font(.headline)
                Spacer()
                Text("\(meal.calories) kcal")
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                macroBadge("탄수 \(meal.carbs)g")
                macroBadge("단백 \(meal.protein)g")
                macroBadge("지방 \(meal.fat)g")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func macroBadge(_ text: String) -> some View {
        Text(text)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray5))
            .clipShape(Capsule())
    }

    private var canSave: Bool {
        guard let calories, let carbs, let protein, let fat else { return false }
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && calories >= 0 && carbs >= 0 && protein >= 0 && fat >= 0
    }

    private func resetForm() {
        name = ""
        calories = nil
        carbs = nil
        protein = nil
        fat = nil
    }

    private func saveMeal() {
        guard let calories, let carbs, let protein, let fat else { return }
        viewModel.addMeal(name: name, calories: calories, carbs: carbs, protein: protein, fat: fat)
        resetForm()
        isPresentingAdd = false
    }

    private func handleSearchChange(_ newValue: String) {
        let trimmed = newValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if trimmed.isEmpty {
            viewModel.clearSearchFilter()
        } else {
            viewModel.applySearchFilter(with: trimmed)
        }
    }
}

#Preview {
    PreviewTodayMealsView()
}

@MainActor
private struct PreviewTodayMealsView: View {
    private let context = PersistenceController.preview.container.viewContext

    var body: some View {
        TodayMealsView(context: context)
    }
}
