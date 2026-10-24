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
            AppBackground(
                imageName: currentStep == 0 ? "bg_sakura_tree" : "bg_mountain_dawn",
                opacity: currentStep == 0 ? 0.38 : 0.16,
                showMist: currentStep != 0
            )
            AmbientPetalsView()
            
            VStack(spacing: 0) {
                // Progress indicator (only on setup steps 1..3)
                if currentStep > 0 {
                    progressBar
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                }
                
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
                    .fill(
                        index <= currentStep
                            ? LinearGradient.zenCtaGradient
                            : LinearGradient(colors: [Color.white.opacity(0.6), Color.white.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 5)
                    .overlay(
                        Capsule()
                            .stroke(index <= currentStep ? Color.zenGold.opacity(0.6) : Color.zenPlumBorder, lineWidth: 1)
                    )
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }
    
    // MARK: - Step 0: Welcome Step (Landing Page)
    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            
            // Left-aligned Thematic Visual: Red Lucky Fortune Pouch with decreased size and soft opacity
            HStack {
                Image("zen_lucky_envelope")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 155)
                    .opacity(0.48)
                    .shadow(color: Color.zenCrimson.opacity(0.12), radius: 14, y: 5)
                    .shadow(color: Color.zenGold.opacity(0.18), radius: 10, y: 3)
                    .padding(.leading, 16)
                
                Spacer()
            }
            
            Spacer().frame(height: 20)
            
            // Bottom Content Block (Left-aligned orientation matching reference)
            VStack(alignment: .leading, spacing: 14) {
                Text("SafeToSpend")
                    .font(.custom("HiraMinProN-W6", size: 48))
                    .foregroundStyle(Color.zenInk)
                    .tracking(0.6)
                    .shadow(color: Color.white.opacity(0.85), radius: 10, x: 0, y: 2)
                
                Text("Know exactly what is safe to spend today after your bills and savings are protected.")
                    .font(.system(size: 15, weight: .medium, design: .default))
                    .foregroundStyle(Color.zenPlumGrey)
                    .lineSpacing(4)
                    .shadow(color: Color.white.opacity(0.95), radius: 8, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var balanceStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Spacer(minLength: 16)
                
                // Provided Thematic Lucky Envelope Icon
                Image("zen_lucky_envelope")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 90)
                    .shadow(color: Color.zenCrimson.opacity(0.18), radius: 12, y: 5)
                    .shadow(color: Color.zenGold.opacity(0.24), radius: 8, y: 2)
                
                // Left-aligned Title & Subtitle matching landing page alignment & theme
                VStack(alignment: .leading, spacing: 6) {
                    Text("What's your balance?")
                        .font(.custom("HiraMinProN-W6", size: 32))
                        .foregroundStyle(Color.zenInk)
                        .tracking(0.4)
                        .shadow(color: Color.white.opacity(0.85), radius: 8, x: 0, y: 1)
                    
                    Text("Enter your current available bank balance")
                        .font(.system(size: 15, weight: .medium, design: .default))
                        .foregroundStyle(Color.zenPlumGrey)
                }
                
                // Left-aligned Input Area
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("₹")
                            .font(.system(size: 40, weight: .bold, design: .serif))
                            .foregroundStyle(Color.zenCrimson)
                        
                        TextField("0", text: $balanceText)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.zenInk)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.zenCrimson.opacity(0.6), Color.zenGold.opacity(0.4), Color.zenMist.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                    
                    Text("This is the money you have right now")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.zenLavenderGrey)
                }
                .padding(.top, 10)
                
                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
        }
        .scrollBounceBehavior(.always, axes: .vertical)
        .scrollDismissesKeyboard(.interactively)
    }
    
    private var cycleStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Spacer(minLength: 16)
                
                // Left-aligned Title & Subtitle matching theme (No icon above heading as requested)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your pay cycle")
                        .font(.custom("HiraMinProN-W6", size: 32))
                        .foregroundStyle(Color.zenInk)
                        .tracking(0.4)
                        .shadow(color: Color.white.opacity(0.85), radius: 8, x: 0, y: 1)
                    
                    Text("When does your salary month start & end?")
                        .font(.system(size: 15, weight: .medium, design: .default))
                        .foregroundStyle(Color.zenPlumGrey)
                }
                
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
                .padding(.top, 10)
                
                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
        }
        .scrollBounceBehavior(.always, axes: .vertical)
    }
    
    private var safetyStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Spacer(minLength: 16)
                
                // Left-aligned Title & Subtitle matching theme (No icon above heading as requested)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Safety Net")
                        .font(.custom("HiraMinProN-W6", size: 32))
                        .foregroundStyle(Color.zenInk)
                        .tracking(0.4)
                        .shadow(color: Color.white.opacity(0.85), radius: 8, x: 0, y: 1)
                    
                    Text("Optional: set aside money you don't want to touch")
                        .font(.system(size: 15, weight: .medium, design: .default))
                        .foregroundStyle(Color.zenPlumGrey)
                }
                
                VStack(spacing: 16) {
                    inputCard(
                        title: "Safety Buffer",
                        icon: "shield.lefthalf.filled",
                        placeholder: "0",
                        text: $safetyBufferText,
                        hint: "Emergency cushion (won't be counted as spendable)"
                    )
                    
                    inputCard(
                        title: "Savings Reserve",
                        icon: "banknote.fill",
                        placeholder: "0",
                        text: $savingsText,
                        hint: "Money you're saving this cycle"
                    )
                }
                .padding(.top, 10)
                
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13, weight: .medium))
                    Text("You can skip this and adjust anytime later")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Color.zenLavenderGrey)
                .padding(.leading, 4)
                
                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
        }
        .scrollBounceBehavior(.always, axes: .vertical)
        .scrollDismissesKeyboard(.interactively)
    }
    
    // MARK: - Reusable Components
    
    private func datePickerCard(title: String, icon: String, date: Binding<Date>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.zenCrimson)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.zenInk)
            
            Spacer()
            
            // Explicit formatted date badge ensuring consistent "24 Nov 2026" format
            ZStack {
                Text(formatCycleDate(date.wrappedValue))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.zenInk)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.zenPlumBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.zenInk.opacity(0.04), radius: 4, y: 2)
                
                DatePicker("", selection: date, displayedComponents: .date)
                    .labelsHidden()
                    .opacity(0.015)
            }
        }
        .cardStyle()
    }
    
    private func formatCycleDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
    
    private func inputCard(title: String, icon: String, placeholder: String, text: Binding<String>, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.zenCrimson)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.zenInk)
                
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("₹")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(Color.zenCrimson)
                
                TextField(placeholder, text: text)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.zenInk)
                    .keyboardType(.numberPad)
            }
            .padding(.vertical, 2)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.zenCrimson.opacity(0.35), Color.zenGold.opacity(0.2), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
            
            Text(hint)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.zenPlumGrey)
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
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.zenInk)
                        .frame(width: 52, height: 52)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.zenPlumBorder, lineWidth: 1)
                        )
                        .shadow(color: Color.zenInk.opacity(0.06), radius: 6, y: 3)
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
                        Text((currentStep == 0 || currentStep == steps.count - 1) ? "Get Started" : "Continue")
                            .font(.zenHeading(17, weight: .bold))
                        
                        if currentStep > 0 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: currentStep == 0 ? .infinity : nil)
                .padding(.horizontal, currentStep == 0 ? 0 : 32)
                .padding(.vertical, 18)
                .background(LinearGradient.zenCtaGradient)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.zenGold.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: Color.zenCrimson.opacity(0.35), radius: 10, y: 4)
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
