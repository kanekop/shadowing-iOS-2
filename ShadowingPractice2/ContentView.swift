import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MaterialsListView()
                .tabItem {
                    Label("教材", systemImage: "folder.fill")
                }
                .tag(0)
            
            PracticeView()
                .tabItem {
                    Label("練習", systemImage: "mic.fill")
                }
                .tag(1)
            
            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "clock.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
}
