import SwiftUI

struct ExportDataSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var expenses: [ExpenseResponse] = []
    @State private var bills: [BillResponse] = []
    @State private var isLoadingData = true
    @State private var isExporting = false
    @State private var activeShareURL: URL?
    @State private var showShareSheet = false
    @State private var statusMessage: String?
    
    var body: some View {
        ZStack {
            Color.stsCardBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary card
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("DATA SUMMARY")
                                    .font(.stsCaption)
                                    .foregroundStyle(.stsSecondary)
                                Spacer()
                                if isLoadingData {
                                    ProgressView()
                                        .tint(.stsAccent)
                                }
                            }
                            
                            HStack(spacing: 16) {
                                summaryTile(
                                    title: "Expenses",
                                    value: "\(expenses.count)",
                                    icon: "creditcard.fill",
                                    color: .stsCyan
                                )
                                
                                summaryTile(
                                    title: "Bills",
                                    value: "\(bills.count)",
                                    icon: "doc.text.fill",
                                    color: .stsAccent
                                )
                            }
                        }
                        .padding(18)
                        .background(Color.stsElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.stsBorder, lineWidth: 1)
                        )
                        
                        // Export options
                        VStack(spacing: 12) {
                            exportOptionRow(
                                title: "Export as CSV (Spreadsheet)",
                                subtitle: "Compatible with Excel, Numbers, and Google Sheets. Includes full expense and bill breakdown.",
                                icon: "tablecells.badge.ellipsis",
                                color: .stsCyan,
                                isLoading: isExporting && activeShareURL == nil
                            ) {
                                exportCSV()
                            }
                            
                            exportOptionRow(
                                title: "Export Full JSON Backup",
                                subtitle: "Complete structured data backup of your cycles, expenses, and commitments for restore or migration.",
                                icon: "arrow.down.doc.fill",
                                color: .stsAccent,
                                isLoading: isExporting
                            ) {
                                exportJSON()
                            }
                        }
                        
                        if let status = statusMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.stsSuccess)
                                Text(status)
                                    .font(.stsSmall)
                                    .foregroundStyle(.stsSecondary)
                            }
                            .padding(.top, 4)
                        }
                        
                        // Security notice
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.caption)
                                    .foregroundStyle(.stsAccent)
                                Text("PRIVACY SAFE")
                                    .font(.stsCaption)
                                    .foregroundStyle(.stsAccent)
                            }
                            Text("Exported files are generated on your device and shared directly through your system share sheet. Your data never touches third-party trackers.")
                                .font(.stsSmall)
                                .foregroundStyle(.stsTertiary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.stsAccent.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.stsAccent.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.stsAccent)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = activeShareURL {
                    ActivityShareSheet(activityItems: [url])
                }
            }
            .task {
                await loadCurrentData()
            }
    }
    
    // MARK: - Components
    
    private func summaryTile(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.stsHeadline)
                    .foregroundStyle(.stsPrimary)
                Text(title)
                    .font(.stsSmall)
                    .foregroundStyle(.stsSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.stsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func exportOptionRow(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        isLoading: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 42, height: 42)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.stsBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(.stsPrimary)
                    
                    Text(subtitle)
                        .font(.stsSmall)
                        .foregroundStyle(.stsSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                    .foregroundStyle(.stsAccent)
                    .padding(.top, 2)
            }
            .padding(16)
            .background(Color.stsElevated)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.stsBorder, lineWidth: 1)
            )
        }
        .disabled(isLoading || isLoadingData)
    }
    
    // MARK: - Actions
    
    private func loadCurrentData() async {
        isLoadingData = true
        defer { isLoadingData = false }
        
        async let expensesTask = APIClient.shared.listExpenses()
        async let billsTask = APIClient.shared.listBills()
        
        do {
            expenses = (try? await expensesTask) ?? []
            bills = (try? await billsTask) ?? []
        }
    }
    
    private func exportCSV() {
        guard let url = ExportService.shared.generateExpensesCSV(expenses: expenses, bills: bills) else {
            statusMessage = "Could not generate CSV"
            return
        }
        activeShareURL = url
        statusMessage = "CSV generated: \(url.lastPathComponent)"
        showShareSheet = true
    }
    
    private func exportJSON() {
        isExporting = true
        Task {
            do {
                let raw = try await APIClient.shared.exportData()
                if let url = ExportService.shared.generateJSONBackup(rawJSON: raw) {
                    activeShareURL = url
                    statusMessage = "JSON backup generated: \(url.lastPathComponent)"
                    showShareSheet = true
                } else {
                    statusMessage = "Could not create backup file"
                }
            } catch {
                statusMessage = "Export failed: \(error.localizedDescription)"
            }
            isExporting = false
        }
    }
}
