//
//  AppDelegate.swift
//  FinderPlus
//
//  Created by Viktor Varenik on 10.08.2022.
//

import Cocoa
import FinderSync
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        FIFinderSyncController.showExtensionManagementInterface()
        
        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("通知权限已获得")
            } else if let error = error {
                print("请求通知权限出错: \(error.localizedDescription)")
            }
        }
        
        //NSApplication.shared.terminate(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
