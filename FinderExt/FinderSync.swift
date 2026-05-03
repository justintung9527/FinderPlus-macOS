//
//  FinderSync.swift
//  FinderExt
//
//  Created by Viktor Varenik on 10.08.2022.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
    
    override init() {
        super.init()
        
        // set up the directory we are syncing
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        // produce a menu for the extension
        let menu = NSMenu(title: "")
        menu.addItem(withTitle: "新建文件", action: #selector(createEmptyFileClicked(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "复制路径", action: #selector(copyPathClicked(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "用TRAE打开", action: #selector(openTraeClicked(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "用Zed打开", action: #selector(openZedClicked(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "进入Ghostty", action: #selector(openGhosttyClicked(_:)), keyEquivalent: "")

        return menu
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
