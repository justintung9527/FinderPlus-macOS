//
//  FinderSync.swift
//  FinderExt
//
//  Created by Viktor Varenik on 10.08.2022.
//

import Cocoa
import FinderSync
import UserNotifications

class FinderSync: FIFinderSync {
    
    override init() {
        super.init()
        
        // set up the directory we are syncing
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
        
        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("请求通知权限失败: \(error.localizedDescription)")
            }
        }
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        // produce a menu for the extension
        let menu = NSMenu(title: "")
        
        let parentItem = NSMenuItem(title: "进入父目录", action: #selector(openParentDirectoryClicked(_:)), keyEquivalent: "")
        parentItem.image = NSImage(systemSymbolName: "arrow.up.circle", accessibilityDescription: nil)
        menu.addItem(parentItem)

        
        let copyPathItem = NSMenuItem(title: "复制路径", action: #selector(copyPathClicked(_:)), keyEquivalent: "")
        copyPathItem.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil)
        menu.addItem(copyPathItem)
        
        let createFileItem = NSMenuItem(title: "新建TXT文件", action: #selector(createEmptyFileClicked(_:)), keyEquivalent: "")
        createFileItem.image = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil)
        menu.addItem(createFileItem)
        
        let openTraeItem = NSMenuItem(title: "用TRAE打开", action: #selector(openTraeClicked(_:)), keyEquivalent: "")
        openTraeItem.image = NSImage(systemSymbolName: "arrow.up.right.square", accessibilityDescription: nil)
        menu.addItem(openTraeItem)
        
        let openZedItem = NSMenuItem(title: "用Zed打开", action: #selector(openZedClicked(_:)), keyEquivalent: "")
        openZedItem.image = NSImage(systemSymbolName: "arrow.up.right.square", accessibilityDescription: nil)
        menu.addItem(openZedItem)
        
        let openGhosttyItem = NSMenuItem(title: "进入Ghostty", action: #selector(openGhosttyClicked(_:)), keyEquivalent: "")
        openGhosttyItem.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: nil)
        menu.addItem(openGhosttyItem)

        return menu
    }
    @IBAction func openParentDirectoryClicked(_ sender: AnyObject?) {
        guard let target = FIFinderSyncController.default().targetedURL() else {
            return
        }
        // 使用 standardized 获取标准化路径，避免尾部斜杠或符号链接导致删除组件失败
        let currentURL = target.standardized
        let parentURL = currentURL.deletingLastPathComponent().standardized
        
        // 如果当前路径已经是根目录，或者删除最后一部分后路径没变，说明已在根目录
        if currentURL.path == "/" || parentURL.path == currentURL.path {
            let content = UNMutableNotificationContent()
            content.title = "提示"
            content.body = "已在根目录"
            content.sound = .default
            
            let request = UNNotificationRequest(identifier: "FinderPlusRootDirectory", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("发送原生通知失败: \(error.localizedDescription)")
                }
            }
            return
        }
        
        // 使用系统 open 命令打开父目录，以解决沙盒权限问题
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = [parentURL.path]
        
        do {
            try task.run()
        } catch let error as NSError {
            print("进入父目录失败: \(error.localizedDescription)")
        }
    }
    @IBAction func copyPathClicked(_ sender: AnyObject?) {
        let items = FIFinderSyncController.default().selectedItemURLs() ?? []
        
        var paths: [String] = []
        if !items.isEmpty {
            paths = items.map { $0.path }
        } else if let target = FIFinderSyncController.default().targetedURL() {
            paths = [target.path]
        }
        
        guard !paths.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(paths as [NSString])
    }
    @IBAction func openZedClicked(_ sender: AnyObject?) {
        let items = FIFinderSyncController.default().selectedItemURLs() ?? []
        
        var urlsToOpen: [URL] = []
        if !items.isEmpty {
            urlsToOpen = items
        } else if let target = FIFinderSyncController.default().targetedURL() {
            urlsToOpen = [target]
        }
        
        guard !urlsToOpen.isEmpty else { return }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        
        var arguments = ["-a", "zed"]
        for url in urlsToOpen {
            arguments.append(url.path)
        }
        task.arguments = arguments
        
        do {
            try task.run()
        } catch let error as NSError {
            print("Zed.app打开失败: \(error.description)")
        }
    }
    @IBAction func openTraeClicked(_ sender: AnyObject?) {
        let items = FIFinderSyncController.default().selectedItemURLs() ?? []
        
        var urlsToOpen: [URL] = []
        if !items.isEmpty {
            urlsToOpen = items
        } else if let target = FIFinderSyncController.default().targetedURL() {
            urlsToOpen = [target]
        }
        
        guard !urlsToOpen.isEmpty else { return }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        
        var arguments = ["-a", "trae"]
        for url in urlsToOpen {
            arguments.append(url.path)
        }
        task.arguments = arguments
        
        do {
            try task.run()
        } catch let error as NSError {
            print("Trae.app打开失败: \(error.description)")
        }
    }
    /// Open a macOS ghostty window in current folder
    @IBAction func openGhosttyClicked(_ sender: AnyObject?) {
        guard let target = FIFinderSyncController.default().targetedURL() else {
            return
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-a", "ghostty", "\(target.path)"]
        
        do {
            try task.run()
        } catch let error as NSError {
            print("进入Ghostty失败: \(error.description)")
        }
    }

    /// Creates an empty file with name "untitled" under the user-chosen Finder folder.
    /// If file already exists, append it with a counter.
    @IBAction func createEmptyFileClicked(_ sender: AnyObject?) {
        guard let target = FIFinderSyncController.default().targetedURL() else {
            return
        }

        var originalPath = target
        let originalFilename = "未命名"
        var filename = "未命名.txt"
        let fileType = ".txt"
        var counter = 1
        
        while FileManager.default.fileExists(atPath: originalPath.appendingPathComponent(filename).path) {
            filename = "\(originalFilename)\(counter)\(fileType)"
            counter+=1
            originalPath = target
        }
        
        let fileURL = target.appendingPathComponent(filename)
        do {
            try "".write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
            
            // 使用默认编辑器打开新创建的文件
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            task.arguments = [fileURL.path]
            try task.run()
        } catch let error as NSError {
            print("创建或打开文件失败: \(error.description)")
        }
    }
}
