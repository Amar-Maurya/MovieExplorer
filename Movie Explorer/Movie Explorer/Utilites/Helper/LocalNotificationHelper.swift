//
//  LocalNotificationHelper.swift
//  MovieExplorer
//
//  Created by amar maurya on 27/07/25.
//

import UserNotifications
import UIKit

final class LocalNotificationHelper: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotificationHelper()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Request Notification Permission
    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    DispatchQueue.main.async {
                        completion?(granted)
                    }
                }
            case .denied:
                DispatchQueue.main.async {
                    completion?(false)
                }
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    completion?(true)
                }
            @unknown default:
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
    }

    // MARK: - Send Notification
    func sendNotification(title: String, body: String) {
        requestPermission { granted in
            guard granted else {
                print("Notification permission not granted.")
                return
            }
            let notificationCenter = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            let ideintifer = "movie.explorer.com.notification"
            content.title = title
            content.body = body
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: ideintifer,
                content: content,
                trigger: nil
            )
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [ideintifer])
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Show Notification in Foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func notifyMovieAdded(_ movieTitle: String) {
        sendNotification(
            title: NotificationConstants.Titles.added,
            body: NotificationConstants.Messages.added(movie: movieTitle)
        )
    }

    func notifyMovieRemoved(_ movieTitle: String) {
        sendNotification(
            title: NotificationConstants.Titles.removed,
            body: NotificationConstants.Messages.removed(movie: movieTitle)
        )
    }

    func notifyFavoritesCleared() {
        sendNotification(
            title: NotificationConstants.Titles.cleared,
            body: NotificationConstants.Messages.cleared
        )
    }
}
