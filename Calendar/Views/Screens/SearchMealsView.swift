import SwiftUI
import CoreData

struct SearchMealsView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TodayMealsViewModel

    @State private var searchText: String = ""
    @State private var allMeals: [MealEntity] = []
    @State private var isLoading: Bool = false
    @State private var loadErrorMessage: String?

    // NEW: flag to detect whether Core Data stores exist
    private var hasPersistentStore: Bool {
        guard let coordinator = context.persistentStoreCoordinator else { return false }
        return !coordinator.persistentStores.isEmpty
    }

    // 필터링된 결과
    private var filteredMeals: [MealEntity] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return allMeals }

        return allMeals.filter { meal in
            let name = meal.name ?? ""
            return name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                // 1) Preview 등에서 persistent store가 없을 때
                if !hasPersistentStore {
                    VStack(spacing: 8) {
                        Text("프리뷰 모드입니다.")
                            .font(.headline)
                        Text("실제 앱 실행 시에는 저장된 식단을 검색할 수 있습니다.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                // 2) 로딩 중
                else if isLoading {
                    ProgressView("식단 불러오는 중…")
                }
                // 3) 에러 발생
                else if let errorMessage = loadErrorMessage {
                    VStack(spacing: 12) {
                        Text("식단을 불러오지 못했습니다.")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                        Button("다시 시도하기") {
                            loadMeals()
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
                // 4) 결과 없음
                else if filteredMeals.isEmpty {
                    VStack(spacing: 8) {
                        Text("검색 결과가 없습니다.")
                            .font(.headline)
                        Text("위의 검색창에 식단 이름을 입력해 보세요.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                // 5) 결과 리스트
                else {
                    List {
                        ForEach(filteredMeals, id: \.objectID) { meal in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(meal.name ?? "이름 없음")
                                        .font(.headline)
                                    Spacer()
                                    Button("오늘 추가") {
                                        viewModel.copyMealToToday(meal)
                                    }
                                    .font(.caption)
                                }

                                let calories = meal.calories
                                let carbs    = meal.carbs
                                let protein  = meal.protein
                                let fat      = meal.fat

                                Text("\(calories) kcal")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                HStack(spacing: 8) {
                                    Text("탄수 \(carbs) g")
                                    Text("단백질 \(protein) g")
                                    Text("지방 \(fat) g")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)

                                if let eatenAt = meal.eatenAt {
                                    Text(eatenAt, style: .date)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let date = meal.eatenAt {
                                    viewModel.goTo(date: date)
                                }
                                dismiss()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("식단 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "식단 이름 검색")
        .onAppear {
            // Preview(= store 없음)에서는 fetch 시도 안 함
            if hasPersistentStore && allMeals.isEmpty {
                loadMeals()
            }
        }
    }

    private func loadMeals() {
        isLoading = true
        loadErrorMessage = nil

        allMeals = viewModel.allMeals()
        isLoading = false
    }
}
