import Foundation
import SwiftData

@Model
class WorkoutTemplate {
    var id: UUID
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TemplateEntry.template)
    var entries: [TemplateEntry] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }

    var sortedEntries: [TemplateEntry] {
        entries.sorted { $0.order < $1.order }
    }
}
