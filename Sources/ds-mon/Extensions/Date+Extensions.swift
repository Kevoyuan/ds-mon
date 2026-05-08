import Foundation

extension Date {
    static var todayStart: Date {
        Calendar.current.startOfDay(for: Date())
    }

    static var monthStart: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: Date())
        return Calendar.current.date(from: components) ?? Date()
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var dayString: String {
        let f = DateFormatter()
        f.dateFormat = "MM/dd"
        return f.string(from: self)
    }

    var fullDayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }

    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
