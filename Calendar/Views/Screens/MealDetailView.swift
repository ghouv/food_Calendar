import SwiftUI

struct MealDetailView: View {
    @ObservedObject var viewModel: TodayMealsViewModel
    let meal: MealEntity
    @Environment(\.dismiss) private var dismiss

    @State private var isPresentingEdit = false
    @State private var editName = ""
    @State private var editCalories: Int? = nil
    @State private var editCarbs: Int? = nil
    @State private var editProtein: Int? = nil
    @State private var editFat: Int? = nil

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        return formatter
    }()

    private var formattedDate: String {
        if let eatenAt = meal.eatenAt {
            return dateFormatter.string(from: eatenAt)
        }
        return ""
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(meal.name ?? "")
                    .font(.largeTitle.bold())
                Text("오늘의 식단 요약")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text(formattedDate)
                        .font(.headline)
                    Text("\(meal.calories) kcal")
                        .font(.title2.weight(.semibold))
                }

                HStack(spacing: 8) {
                    macroChip(title: "탄수", value: Int(meal.carbs), unit: "g")
                    macroChip(title: "단백", value: Int(meal.protein), unit: "g")
                    macroChip(title: "지방", value: Int(meal.fat), unit: "g")
                }

                Button {
                    viewModel.toggleFavorite(for: meal)
                } label: {
                    Label(meal.isFavorite ? "즐겨찾기 해제" : "즐겨찾기 추가", systemImage: meal.isFavorite ? "star.fill" : "star")
                        .foregroundColor(meal.isFavorite ? .yellow : .accentColor)
                }
                .buttonStyle(.bordered)

                HStack(spacing: 12) {
                    Button("편집") {
                        startEditing()
                    }
                    .buttonStyle(.bordered)

                    Button("삭제", role: .destructive) {
                        viewModel.deleteMeal(meal)
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .sheet(isPresented: $isPresentingEdit) {
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
                        Button("취소") { isPresentingEdit = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장") { saveEdits() }
                            .disabled(!canSaveEdits)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func macroChip(title: String, value: Int, unit: String) -> some View {
        Text("\(title) \(value)\(unit)")
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray5))
            .clipShape(Capsule())
    }

    private func startEditing() {
        editName = meal.name ?? ""
        editCalories = Int(meal.calories)
        editCarbs = Int(meal.carbs)
        editProtein = Int(meal.protein)
        editFat = Int(meal.fat)
        isPresentingEdit = true
    }

    private var canSaveEdits: Bool {
        guard let editCalories, let editCarbs, let editProtein, let editFat else { return false }
        return !editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && editCalories >= 0 && editCarbs >= 0 && editProtein >= 0 && editFat >= 0
    }

    private func saveEdits() {
        guard let editCalories, let editCarbs, let editProtein, let editFat else { return }
        viewModel.updateMeal(meal, name: editName, calories: editCalories, carbs: editCarbs, protein: editProtein, fat: editFat)
        isPresentingEdit = false
    }
}

#Preview {
    let vm = TodayMealsViewModel(context: PersistenceController.shared.viewContext)
    let sample = MealEntity(context: PersistenceController.shared.viewContext)
    sample.id = UUID()
    sample.name = "샘플 식사"
    sample.calories = 450
    sample.carbs = 50
    sample.protein = 30
    sample.fat = 12
    sample.eatenAt = Date()
    return MealDetailView(viewModel: vm, meal: sample)
}
