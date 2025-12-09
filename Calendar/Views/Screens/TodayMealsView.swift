import SwiftUI
import CoreData

struct TodayMealsView: View {
    @StateObject private var viewModel: TodayMealsViewModel
    @State private var isPresentingAdd = false
    @State private var name = ""
    @State private var calories: Int? = nil
    @State private var carbs: Int? = nil
    @State private var protein: Int? = nil
    @State private var fat: Int? = nil

    @State private var mealBeingEdited: MealEntity? = nil
    @State private var editName = ""
    @State private var editCalories: Int? = nil
    @State private var editCarbs: Int? = nil
    @State private var editProtein: Int? = nil
    @State private var editFat: Int? = nil

    init(viewModel: TodayMealsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: TodayMealsViewModel(context: context))
    }

    private var formattedDate: String {
        viewModel.selectedDate.formatted(.dateTime.month().day().weekday(.abbreviated)).replacingOccurrences(of: ",", with: "")
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        dateHeader
                        summaryCard
                    }
                    .listRowInsets(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
                }

                Section("오늘의 식사") {
                    ForEach(viewModel.mealsForSelectedDate, id: \.objectID) { meal in
                        mealRow(meal)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                startEditing(meal)
                            }
                    }
                    .onDelete(perform: viewModel.deleteMeals(at:))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("식단 캘린더")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAdd) {
                NavigationStack {
                    Form {
                        Section("이름") {
                            TextField("예: 닭가슴살 샐러드", text: $name)
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
            .sheet(item: $mealBeingEdited) { meal in
                NavigationStack {
                    Form {
                        Section("이름") {
                            TextField("예: 닭가슴살 샐러드", text: $editName)
                        }
                        Section("영양 정보") {
                            TextField("칼로리", value: $editCalories, format: .number)
                                .keyboardType(.numberPad)
                            TextField("탄수화물 (g)", value: $editCarbs, format: .number)
                                .keyboardType(.numberPad)
                            TextField("단백질 (g)", value: $editProtein, format: .number)
                                .keyboardType(.numberPad)
                            TextField("지방 (g)", value: $editFat, format: .number)
                                .keyboardType(.numberPad)
                        }
                    }
                    .navigationTitle("식사 수정")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("취소") {
                                mealBeingEdited = nil
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("저장") {
                                saveEdits(for: meal)
                            }
                            .disabled(!canSaveEdits)
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private var dateHeader: some View {
        HStack {
            Button {
                viewModel.changeSelectedDate(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(formattedDate)
                .font(.headline)

            Spacer()

            Button {
                viewModel.changeSelectedDate(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
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

    private func startEditing(_ meal: MealEntity) {
        mealBeingEdited = meal
        editName = meal.name ?? ""
        editCalories = Int(meal.calories)
        editCarbs = Int(meal.carbs)
        editProtein = Int(meal.protein)
        editFat = Int(meal.fat)
    }

    private var canSaveEdits: Bool {
        guard let editCalories, let editCarbs, let editProtein, let editFat else { return false }
        return !editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && editCalories >= 0 && editCarbs >= 0 && editProtein >= 0 && editFat >= 0
    }

    private func saveEdits(for meal: MealEntity) {
        guard let editCalories, let editCarbs, let editProtein, let editFat else { return }
        viewModel.updateMeal(meal, name: editName, calories: editCalories, carbs: editCarbs, protein: editProtein, fat: editFat)
        mealBeingEdited = nil
    }
}

#Preview {
    TodayMealsView(context: PersistenceController.shared.viewContext)
}
