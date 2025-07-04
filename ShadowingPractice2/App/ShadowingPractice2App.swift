import SwiftUI
import AVFoundation
import Speech
import UIKit

@main
struct ShadowingPractice2App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        setupApp()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    requestPermissions()
                }
        }
    }
    
    private func setupApp() {
        // ディレクトリの作成
        createAppDirectories()
        
        // オーディオセッションの設定
        configureAudioSession()
        
        // ログの初期化
        Logger.shared.info("App launched")
    }
    
    private func createAppDirectories() {
        // FileManager extensionsの静的プロパティが自動的にディレクトリを作成するため、
        // 明示的な作成は不要です。ただし、初期化時にアクセスして作成を確実にします。
        _ = FileManager.materialsDirectory
        _ = FileManager.practicesDirectory
        _ = FileManager.metadataDirectory
        _ = FileManager.cacheDirectory
        
        Logger.shared.info("App directories initialized")
    }
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(false)
        } catch {
            Logger.shared.error("Failed to configure audio session: \(error)")
        }
    }
    
    private func requestPermissions() {
        // マイク権限
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                Logger.shared.info("Microphone permission granted")
            } else {
                Logger.shared.warning("Microphone permission denied")
            }
        }
        
        // 音声認識権限
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .authorized:
                Logger.shared.info("Speech recognition authorized")
            case .denied:
                Logger.shared.warning("Speech recognition denied")
            case .restricted:
                Logger.shared.warning("Speech recognition restricted")
            case .notDetermined:
                Logger.shared.info("Speech recognition not determined")
            @unknown default:
                break
            }
        }
    }
}

// App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // バックグラウンドでの音声処理を有効化
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers])
        } catch {
            Logger.shared.error("Failed to set audio session category: \(error)")
        }
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // バックグラウンド処理
        Logger.shared.info("App entered background")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // フォアグラウンド復帰処理
        Logger.shared.info("App will enter foreground")
    }
}
