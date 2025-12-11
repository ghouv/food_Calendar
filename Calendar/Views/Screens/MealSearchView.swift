import SwiftUI
import CoreData

struct MealSearchView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""

    /// Called when the user selects a meal from the search results
    let onSelect: (MealEntity) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredMeals) { meal in
                    Button {
                        onSelect(meal)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(meal.name ?? "이름 없음")
                                .font(.headline)

                            HStack(spacing: 8) {
                                Text("\(meal.calories) kcal")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                if meal.carbs > 0 {
                                    Text("탄수 \(meal.carbs)g")
                                        .font(.caption)
                                }
                                if meal.protein > 0 {
                                    Text("단백질 \(meal.protein)g")
                                        .font(.caption)
                                }
                                if meal.fat > 0 {
                                    Text("지방 \(meal.fat)g")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("식단 검색")
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "음식 이름을 입력하세요"
            )
        }
    }

    /// Fetches meals from Core Data and filters them by the search query.
    /// This uses the correct entity (MealEntity) and attribute names.
    private var filteredMeals: [MealEntity] {
        let request: NSFetchRequest<MealEntity> = MealEntity.fetchRequest()
        // Sort by eatenAt descending (recent first)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \MealEntity.eatenAt, ascending: false)
        ]

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            // 'name' must match the attribute name in the .xcdatamodeld
            request.predicate = NSPredicate(
                format: "name CONTAINS[cd] %@",
                trimmed
            )
        } else {
            request.predicate = nil
        }

        do {
            return try context.fetch(request)
        } catch {
            print("MealSearchView fetch error:", error)
            return []
        }
    }
}
