import Foundation
import CoreData

struct PersistenceController {
    // Shared instance for the real app (ON-DISK, data survives app restarts)
    static let shared = PersistenceController()

    // Preview-only instance (IN-MEMORY, reset every time)
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)

        // Optionally seed some sample data here if needed
        let context = controller.container.viewContext

        // Example seeding (can be removed or adjusted):
        let sampleMeal = MealEntity(context: context)
        sampleMeal.id = UUID()
        sampleMeal.name = "샘플 식사"
        sampleMeal.calories = 500
        sampleMeal.carbs = 60
        sampleMeal.protein = 20
        sampleMeal.fat = 15
        sampleMeal.eatenAt = Date()
        sampleMeal.isFavorite = false

        do {
            try context.save()
        } catch {
            print("⚠️ Failed to save preview sample data: \(error)")
        }

        return controller
    }()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// - Parameter inMemory:
    ///   true  -> use /dev/null (for SwiftUI previews only, NOT persisted)
    ///   false -> use default on-disk SQLite store (persisted between launches)
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DietCalendarModel")

        if inMemory {
            // Configure an in-memory store ONLY for previews
            let description: NSPersistentStoreDescription

            if let first = container.persistentStoreDescriptions.first {
                description = first
            } else {
                description = NSPersistentStoreDescription()
            }

            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }
        // IMPORTANT:
        // When inMemory == false, DO NOT touch `persistentStoreDescriptions.url`.
        // This allows Core Data to create and use the default SQLite file on disk.

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
