//
//  CacheCleanupOperation.swift
//  Cargo
//
//  Created by Skylar Schipper on 6/8/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc(CARCacheCleanupOperation)
public class CacheCleanupOperation : Operation {
    private var taskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid

    public override init() {
        super.init()

        self.taskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "com.skylarsch.cargo-cleanup", expirationHandler: { [weak self] in
            self?.taskIdentifier = UIBackgroundTaskInvalid
        })
    }
    
    public override func main() {
        if self.taskIdentifier == UIBackgroundTaskInvalid {
            return
        }
        defer {
            if self.taskIdentifier != UIBackgroundTaskInvalid {
                UIApplication.shared.endBackgroundTask(self.taskIdentifier)
            }
            self.taskIdentifier = UIBackgroundTaskInvalid
        }

        do {
            try self.perform()
        } catch {
            print("Cache Cleanup Failed:\n\(error)")
        }
    }

    private func perform() throws {
        try Cache.shared.metadata.perform { ctx in
            let expired = NSFetchRequest<CachedFile>(entityName: "CachedFile")
            expired.predicate = NSPredicate(format: "expiresAt <= %@", Date() as CVarArg)
            expired.fetchBatchSize = 100

            let results = try ctx.fetch(expired)
            for file in results {
                ctx.delete(file)
            }

            if ctx.hasChanges {
                try ctx.save()
            }

            Log("Cache cleanup. Removed \(results.count) files")
        }
    }
}
