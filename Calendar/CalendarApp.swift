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
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            let context = persistenceController.container.viewContext

            TodayMealsView(context: context)
                .environment(\.managedObjectContext, context)
        }
    }
}
