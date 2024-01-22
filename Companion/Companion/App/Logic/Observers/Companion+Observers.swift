// Copyright © Rouven Strauss. All rights reserved.

import ART

import Foundation

extension Companion {
  static func referencesOfObservers(
    addedTo logicModule: LogicModule,
    observing model: Model,
    using _: Coeffects
  ) -> [Any] {
    let observers = [
      Self.permanentChangeObserver(savingChangesUsing: model),
    ]

    Task {
      for tuple in observers {
        await logicModule.add(tuple.0)
      }
    }

    return observers.map(\.1)
  }

  private static func permanentChangeObserver(
    savingChangesUsing model: Model
  ) -> (ModelObserver<AppState>, Any) {
    let observer = PropertyPathObserver.observer(
      for: \AppState.self,
      initiallyObservedValue: { _ in }
    ) { change in
      Task {
        guard change.current.updateKind == .permanent else {
          return
        }

        let previousData = try! change.previous.data()
        let currentData = try! change.current.data()

        guard previousData != currentData else {
          return
        }

        Self.saveContent(of: model)
      }
    }

    return observer.tuple
  }

  private static let modelSavingLock = NSRecursiveLock()

  private static func saveContent(of model: Model) {
    modelSavingLock.executeWhileLocked {
      do {
        try model.save(in: .standard, forKey: Self.dataStorageKey)
        print("Saved")
      } catch {
        fatalError("")
      }
    }
  }

  static let dataStorageKey = "companion_app_state"
}
