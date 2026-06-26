import Foundation
import UserNotifications
import AppKit

/// Fires a local notification at the user's configured time each day, listing
/// any pending daily items (健身打卡 / 复习笔记). Silent when both are done.
final class DailyReminder: NSObject {
    private let settings: Settings
    private let checkinStore: CheckinStore
    private let noteReviewStore: NoteReviewStore

    private var timer: Timer?
    private let lastFiredKey = "dailyReminderLastFiredDay"
    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let categoryIdentifier = "DAILY_CHECK"
    private static let openActionIdentifier = "DAILY_OPEN"

    init(settings: Settings,
         checkinStore: CheckinStore,
         noteReviewStore: NoteReviewStore) {
        self.settings = settings
        self.checkinStore = checkinStore
        self.noteReviewStore = noteReviewStore
        super.init()

        UNUserNotificationCenter.current().delegate = self
        registerCategory()
        requestAuthorization()
        startTicking()
    }

    private func registerCategory() {
        let open = UNNotificationAction(
            identifier: Self.openActionIdentifier,
            title: "去打卡",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [open],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func startTicking() {
        timer?.invalidate()
        let t = Timer(timeInterval: 30, target: self, selector: #selector(tick),
                      userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        timer = t
        tick()
    }

    @objc private func tick() {
        guard settings.dailyReminderEnabled else { return }

        let now = Date()
        let comps = Calendar.current.dateComponents([.hour, .minute], from: now)
        guard let h = comps.hour, let m = comps.minute else { return }

        let nowMinutes = h * 60 + m
        let targetMinutes = settings.dailyReminderHour * 60 + settings.dailyReminderMinute

        // Fire within a 30-minute window after the target. Catches the case where
        // the Mac was asleep at the exact target time.
        guard nowMinutes >= targetMinutes,
              nowMinutes < targetMinutes + 30 else { return }

        let today = dayFormatter.string(from: now)
        let defaults = UserDefaults.standard
        if defaults.string(forKey: lastFiredKey) == today { return }
        defaults.set(today, forKey: lastFiredKey)

        let fitnessDone = checkinStore.todayChecked
        let notesDone = noteReviewStore.todayReviewed
        if fitnessDone && notesDone { return }   // silent

        sendNotification(fitnessDone: fitnessDone, notesDone: notesDone)
    }

    private func sendNotification(fitnessDone: Bool, notesDone: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "今日打卡提醒"
        switch (fitnessDone, notesDone) {
        case (false, false): content.body = "今天还没健身打卡和复习笔记，去完成吧 💪📒"
        case (false, true):  content.body = "今天还没健身打卡 💪"
        case (true,  false): content.body = "今天还没复习笔记 📒"
        case (true,  true):  return
        }
        content.sound = .default
        content.categoryIdentifier = Self.categoryIdentifier

        let req = UNNotificationRequest(
            identifier: "daily-check-\(dayFormatter.string(from: Date()))",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(req)
    }
}

extension DailyReminder: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            AppRouter.shared.showPopover?()
        }
        completionHandler()
    }
}
