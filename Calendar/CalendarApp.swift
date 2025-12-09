//
//  CalendarApp.swift
//  Calendar
//
//  Created by 박재민 on 12/9/25.
//

import SwiftUI
import CoreData

@main
struct CalendarApp: App {
    let persistenceController = PersistenceController.shared
    private let rootViewModel: TodayMealsViewModel

    init() {
        rootViewModel = TodayMealsViewModel(context: persistenceController.viewContext)
    }

    var body: some Scene {
        WindowGroup {
            TodayMealsView(viewModel: rootViewModel)
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }
    }
}
