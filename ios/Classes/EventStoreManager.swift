import EventKit

class EventStoreManager {
    static let shared = EventStoreManager()
    
    let eventStore: EKEventStore
    
    private init() {
        eventStore = EKEventStore()
    }
}
