import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var balanceText = ""
    @State private var cycleStartDate = Date()
    @State private var cycleEndDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var safetyBufferText = ""
    @State private var savingsText = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let steps = ["Welcome", "Balance", "Cycle", "Safety Net"]
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                // Progress indicator
                progressBar
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                
                // Content
                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    balanceStep.tag(1)
                    cycleStep.tag(2)
                    safetyStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4), value: currentStep)
                
                // Navigation buttons
                navigationButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.stsAccent : Color.stsTertiary.opacity(0.3))
                    .frame(height: 4)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }
    
    // MARK: - Steps
    private var welcomeStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 40)
                
                // App logo
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.stsBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 16, y: 6)
                
                VStack(spacing: 12) {
                    Text("SafeToSpend")
                        .font(.stsLargeTitle)
                        .foregroundStyle(.stsPrimary)
                    
                    Text("Know exactly how much you can\nspend today without breaking\nyour budget.")
                        .font(.stsBody)
                        .foregroundStyle(.stsSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
        .scrollBounceBehavior(.always, axes: .vertical)
    }
    
    private var balanceStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 20)
                
                stepHeader(
                    icon: "wallet.pass.fill",
                    title: "What's your balance?",
                    subtitle: "Enter your current available bank balance"
                )
                
                VStack(spacing: 8) {
                    HStack(alignment: .center, spacing: 4) {
                        Text("₹")
                            .font(.stsHeroAmount)
                            .foregroundStyle(.stsAccent)
                        
                        TextField("0", text: $balanceText)
                            .font(.stsHeroAmount)
                            .foregroundStyle(.stsPrimary)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                    }
                    
                    Rectangle()
                        .fill(Color.stsAccent.opacity(0.3))
                        .frame(height: 2)
                        .padding(.horizontal, 40)
                }
                
                Text("This is the money you have right now")
                    .font(.stsCaption)
                    .foregroundStyle(.stsTertiary)
                
                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
        .scrollBounceBehavior(.always, axes: .vertical)
        .scrollDismissesKeyboard(.interactively)
    }
    
    private var cycleStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 20)
                
                stepHeader(
                    icon: "calendar.circle.fill",
                    title: "Your pay cycle",
                    subtitle: "When does your salary month start & end?"
                )
                
                VStack(spacing: 16) {
                    datePickerCard(
                        title: "Cycle Start",
                        icon: "play.circle.fill",
                        date: $cycleStartDate
                    )
                    
                    datePickerCard(
                        title: "Cycle End",
                        icon: "stop.circle.fill",
                        date: $cycleEndDate
                    )
                }
                
                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
        .scrollBounceBehavior(.always, axes: .vertical)
    }
    
    private var safetyStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 20)
                
                stepHeader(
                    icon: "shield.checkered",
                    title: "Safety Net",
                    subtitle: "Optional: set aside money you don't want to touch"
                )
                
                VStack(spacing: 16) {
                    inputCard(
                        title: "Safety Buffer",
                        placeholder: "0",
                        text: $safetyBufferText,
                        hint: "Emergency cushion (won't be counted as spendable)"
                    )
                    
                    inputCard(
                        title: "Savings Reserve",
                        placeholder: "0",
                        text: $savingsText,
                        hint: "Money you're saving this cycle"
                    )
                }
                
                Text("You can skip this and set it later")
                    .font(.stsCaption)
                    .foregroundStyle(.stsTertiary)
                
                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
        .scrollBounceBehavior(.always, axes: .vertical)
        .scrollDismissesKeyboard(.interactively)
    }
    
    // MARK: - Reusable Components
    
    private func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.stsAccent)
                .symbolEffect(.bounce, value: currentStep)
            
            Text(title)
                .font(.stsTitle)
                .foregroundStyle(.stsPrimary)
            
            Text(subtitle)
                .font(.stsBody)
                .foregroundStyle(.stsSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private func datePickerCard(title: String, icon: String, date: Binding<Date>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.stsAccent)
            
            Text(title)
                .font(.stsHeadline)
                .foregroundStyle(.stsPrimary)
            
            Spacer()
            
            DatePicker("", selection: date, displayedComponents: .date)
                .labelsHidden()
                .tint(.stsAccent)
        }
        .cardStyle()
    }
    
    private func inputCard(title: String, placeholder: String, text: Binding<String>, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.stsCaption)
                .foregroundStyle(.stsSecondary)
            
            HStack {
                Text("₹")
                    .font(.stsTitle)
                    .foregroundStyle(.stsAccent)
                
                TextField(placeholder, text: text)
                    .font(.stsTitle)
                    .foregroundStyle(.stsPrimary)
                    .keyboardType(.numberPad)
            }
            
            Text(hint)
                .font(.stsSmall)
                .foregroundStyle(.stsTertiary)
        }
        .cardStyle()
    }
    
    // MARK: - Navigation
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button {
                    Haptics.selection()
                    withAnimation { currentStep -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.stsHeadline)
                        .foregroundStyle(.stsSecondary)
                        .frame(width: 56, height: 56)
                        .background(Color.stsCardBackground)
                        .clipShape(Circle())
                }
            }
            
            Spacer()
            
            Button {
                Haptics.impact(.medium)
                if currentStep < steps.count - 1 {
                    withAnimation { currentStep += 1 }
                } else {
                    submitOnboarding()
                }
            } label: {
                HStack(spacing: 8) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(currentStep == steps.count - 1 ? "Let's Go" : "Next")
                            .font(.stsHeadline)
                        
                        Image(systemName: currentStep == steps.count - 1 ? "checkmark" : "chevron.right")
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: currentStep == 0 ? .infinity : nil)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color.stsAccent)
                .clipShape(Capsule())
            }
            .disabled(isSubmitting || (currentStep == 1 && balanceText.isEmpty))
            .opacity(isSubmitting || (currentStep == 1 && balanceText.isEmpty) ? 0.6 : 1)
        }
    }
    
    // MARK: - Submit
    
    private func submitOnboarding() {
        guard let balance = Int(balanceText) else {
            errorMessage = "Please enter a valid balance"
            showError = true
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let request = OnboardingCompleteRequest(
            startingBalancePaise: balance * 100,
            cycleStartDate: dateFormatter.string(from: cycleStartDate),
            cycleEndDate: dateFormatter.string(from: cycleEndDate),
            safetyBufferPaise: Int(safetyBufferText).map { $0 * 100 },
            savingsReservePaise: Int(savingsText).map { $0 * 100 },
            timezone: TimeZone.current.identifier
        )
        
        isSubmitting = true
        
        Task {
            await appState.completeOnboarding(request)
            isSubmitting = false
            if let error = appState.error {
                errorMessage = error.message
                showError = true
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
