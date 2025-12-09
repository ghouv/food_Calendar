import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: TodayMealsViewModel
    @Environment(\.dismiss) private var dismiss

    private var favorites: [MealEntity] {
        viewModel.favoriteMeals()
    }

    var body: some View {
        Group {
            if favorites.isEmpty {
                VStack(spacing: 12) {
                    Text("즐겨찾기한 식단이 없습니다.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(favorites, id: \.objectID) { meal in
                        Button {
                            viewModel.addMeal(from: meal)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(meal.name ?? "")
                                        .font(.headline)
                                    Text("탄수 \(meal.carbs)g · 단백 \(meal.protein)g · 지방 \(meal.fat)g")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(meal.calories) kcal")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        viewModel.removeFavorites(at: offsets, from: favorites)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("즐겨찾기")
    }
}

#Preview {
    FavoritesView(viewModel: TodayMealsViewModel(context: PersistenceController.shared.viewContext))
}
