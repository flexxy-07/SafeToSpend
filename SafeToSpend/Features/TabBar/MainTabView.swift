import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var showAddExpense = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                
                ExpenseListView()
                    .tag(1)
                
                // Placeholder for FAB
                Color.clear
                    .tag(2)
                
                BillsView()
                    .tag(3)
                
                ChatView()
                    .tag(4)
            }
            
            // Custom Tab Bar
            customTabBar
        }
        .sheet(isPresented: $showAddExpense, onDismiss: {
            Task {
                await appState.refreshToday()
            }
        }) {
            AddExpenseView()
                .environmentObject(appState)
                .presentationDetents([.large, .medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.stsCardBackground)
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabItem(icon: "house.fill", label: "Today", tag: 0)
            tabItem(icon: "list.bullet.rectangle.fill", label: "Expenses", tag: 1)
            
            // Center FAB
            Button {
                Haptics.impact(.medium)
                showAddExpense = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.stsAccent)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.stsAccent.opacity(0.35), radius: 10, y: 4)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .offset(y: -12)
            }
            .frame(maxWidth: .infinity)
            
            tabItem(icon: "doc.text.fill", label: "Bills", tag: 3)
            tabItem(icon: "sparkles", label: "Safe AI", tag: 4)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Color.stsCardBackground
                .overlay(
                    Rectangle()
                        .fill(Color.stsBorder)
                        .frame(height: 1),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func tabItem(icon: String, label: String, tag: Int) -> some View {
        Button {
            Haptics.selection()
            withAnimation(.spring(response: 0.3)) {
                selectedTab = tag
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .symbolEffect(.bounce, value: selectedTab == tag)
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selectedTab == tag ? .stsAccent : .stsTertiary)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
