import SwiftUI

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isThinking = false
    @State private var selectedTopic: String = "All"
    @FocusState private var isInputFocused: Bool
    
    private let topics = ["All", "Spending", "Budgeting", "Affordability", "Bills", "Rescue"]
    
    private var filteredSuggestions: [PromptSuggestion] {
        if selectedTopic == "All" {
            return promptSuggestions
        }
        return promptSuggestions.filter { $0.category.localizedCaseInsensitiveContains(selectedTopic) }
    }
    
    var body: some View {
        ZStack {
            AppBackground()
                .onTapGesture {
                    isInputFocused = false
                }
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Messages & suggestions area
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 12) {
                            if messages.isEmpty {
                                welcomeCard
                                    .padding(.top, 16)
                                
                                topicFilterBar
                                
                                promptSuggestionsSection
                            } else {
                                ForEach(messages) { message in
                                    messageBubble(message)
                                        .id(message.id)
                                }
                                
                                if isThinking {
                                    thinkingIndicator
                                }
                            }
                            
                            // Bottom spacer so messages clear the input bar
                            Color.clear.frame(height: 20)
                        }
                        .padding(.horizontal, 16)
                    }
                    .scrollBounceBehavior(.always, axes: .vertical)
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation(.spring(response: 0.35)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Horizontally scrollable quick-prompts bar above input when messages are active
                if !messages.isEmpty {
                    floatingQuickChipsView
                }
                
                // Input bar
                inputBar
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.stsAccent)
                    .symbolEffect(.variableColor.iterative, options: .repeating, value: isThinking)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Safe AI")
                        .font(.stsHeadline)
                        .foregroundStyle(.stsPrimary)
                    
                    Text("Powered by Gemini")
                        .font(.stsSmall)
                        .foregroundStyle(.stsTertiary)
                }
            }
            
            Spacer()
            
            if !messages.isEmpty {
                Button {
                    withAnimation {
                        messages.removeAll()
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.stsSmall)
                        .foregroundStyle(.stsTertiary)
                        .padding(8)
                        .background(Color.stsCardBackground)
                        .clipShape(Circle())
                }
            }
            
            Button {
                Task { await getRescuePlan() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "lifepreserver")
                    Text("Rescue")
                }
                .font(.stsCaption)
                .foregroundStyle(.stsWarning)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.stsWarning.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.stsCardBackground.opacity(0.85))
    }
    
    // MARK: - Welcome Card
    private var welcomeCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundStyle(Color.stsAccent)
            
            Text("Ask Safe anything")
                .font(.stsTitle)
                .foregroundStyle(.stsPrimary)
            
            Text("I can help you understand your spending,\nplan budgets, and make smarter decisions")
                .font(.stsBody)
                .foregroundStyle(.stsSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .glassCard()
    }
    
    // MARK: - Topic Filter Bar (Horizontally scrollable)
    private var topicFilterBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested Topics")
                .font(.stsCaption)
                .foregroundStyle(.stsSecondary)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(topics, id: \.self) { topic in
                        Button {
                            Haptics.selection()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTopic = topic
                            }
                        } label: {
                            Text(topic)
                                .font(.stsSmall)
                                .foregroundStyle(selectedTopic == topic ? .white : .stsSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedTopic == topic ? Color.stsAccent : Color.stsCardBackground)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .scrollBounceBehavior(.always, axes: .horizontal)
        }
        .padding(.top, 4)
    }
    
    // MARK: - Prompt Suggestions Section (Vertically scrollable)
    private var promptSuggestionsSection: some View {
        VStack(spacing: 10) {
            ForEach(filteredSuggestions) { item in
                Button {
                    inputText = item.query
                    Task { await sendMessage() }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(item.color)
                            .frame(width: 40, height: 40)
                            .background(item.color.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .font(.stsHeadline)
                                .foregroundStyle(.stsPrimary)
                                .multilineTextAlignment(.leading)
                            
                            Text(item.subtitle)
                                .font(.stsSmall)
                                .foregroundStyle(.stsTertiary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.stsTertiary)
                    }
                    .padding(12)
                    .background(Color.stsCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }
    
    // MARK: - Floating Quick Chips (Horizontally scrollable above input during chat)
    private var floatingQuickChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickPrompts, id: \.self) { prompt in
                    Button {
                        inputText = prompt
                        Task { await sendMessage() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 10))
                            Text(prompt)
                                .font(.stsSmall)
                        }
                        .foregroundStyle(.stsSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.stsCardBackground.opacity(0.9))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        .scrollBounceBehavior(.always, axes: .horizontal)
    }
    
    // MARK: - Message Bubble
    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 48)
            } else {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.stsAccent)
                    .frame(width: 28, height: 28)
                    .background(Color.stsAccent.opacity(0.12))
                    .clipShape(Circle())
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.stsBody)
                    .foregroundStyle(.stsPrimary)
                    .lineSpacing(4)
                
                Text(message.timeString)
                    .font(.system(size: 10))
                    .foregroundStyle(.stsTertiary)
            }
            .padding(12)
            .background(
                message.isUser ? Color.stsAccent.opacity(0.18) : Color.stsCardBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            if !message.isUser {
                Spacer(minLength: 48)
            }
        }
    }
    
    // MARK: - Thinking
    private var thinkingIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundStyle(.stsAccent)
                .frame(width: 28, height: 28)
                .background(Color.stsAccent.opacity(0.12))
                .clipShape(Circle())
            
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.stsSecondary)
                        .frame(width: 6, height: 6)
                        .opacity(0.4)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(i) * 0.2),
                            value: isThinking
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.stsCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            Spacer()
        }
    }
    
    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask Safe anything...", text: $inputText)
                .font(.stsBody)
                .foregroundStyle(.stsPrimary)
                .focused($isInputFocused)
                .onSubmit {
                    Task { await sendMessage() }
                }
            
            Button {
                Task { await sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(inputText.isEmpty ? .stsTertiary : .stsAccent)
            }
            .disabled(inputText.isEmpty || isThinking)
        }
        .padding(12)
        .background(Color.stsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, isInputFocused ? 8 : 96) // Tab bar clearance when keyboard dismissed
    }
    
    // MARK: - Actions
    
    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let userMessage = ChatMessage(text: text, isUser: true)
        messages.append(userMessage)
        inputText = ""
        
        Haptics.impact(.light)
        isThinking = true
        
        do {
            let response = try await APIClient.shared.askSafe(text)
            let aiMessage = ChatMessage(text: response.text, isUser: false)
            messages.append(aiMessage)
        } catch {
            let errorMessage = ChatMessage(text: "Sorry, I couldn't process that right now. Please check your connection and try again.", isUser: false)
            messages.append(errorMessage)
        }
        
        isThinking = false
    }
    
    private func getRescuePlan() async {
        isThinking = true
        
        let userMessage = ChatMessage(text: "Generate a rescue plan for me", isUser: true)
        messages.append(userMessage)
        
        do {
            let response = try await APIClient.shared.getRescuePlan()
            let aiMessage = ChatMessage(text: response.text, isUser: false)
            messages.append(aiMessage)
        } catch {
            let errorMessage = ChatMessage(text: "Couldn't generate a rescue plan at this moment. Try again later.", isUser: false)
            messages.append(errorMessage)
        }
        
        isThinking = false
    }
}

// MARK: - Prompt Suggestion Models
struct PromptSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let query: String
    let icon: String
    let color: Color
    let category: String
}

private let promptSuggestions: [PromptSuggestion] = [
    PromptSuggestion(
        title: "Can I afford dinner tonight?",
        subtitle: "Check against daily safe-to-spend limit",
        query: "Can I afford to spend ₹500 on dinner tonight?",
        icon: "fork.knife",
        color: .stsAccent,
        category: "Affordability"
    ),
    PromptSuggestion(
        title: "How much did I spend on food?",
        subtitle: "Breakdown of food & dining expenses",
        query: "How much have I spent on food this month?",
        icon: "cart.fill",
        color: .stsCyan,
        category: "Spending"
    ),
    PromptSuggestion(
        title: "Am I on track this cycle?",
        subtitle: "Pace calculation & end-of-month projection",
        query: "Am I on track with my spending this cycle?",
        icon: "chart.line.uptrend.xyaxis",
        color: .stsAccent,
        category: "Budgeting"
    ),
    PromptSuggestion(
        title: "Where can I cut back?",
        subtitle: "Identify discretionary spending leaks",
        query: "Where are my biggest spending leaks and how can I cut back?",
        icon: "scissors",
        color: .stsWarning,
        category: "Budgeting"
    ),
    PromptSuggestion(
        title: "Upcoming bills check",
        subtitle: "Review commitments due before next payday",
        query: "What upcoming bills do I need to prepare for?",
        icon: "doc.text.fill",
        color: .stsCyan,
        category: "Bills"
    ),
    PromptSuggestion(
        title: "Emergency Rescue Plan",
        subtitle: "Step-by-step guidance if overspending",
        query: "What should I do if I have overspent my budget?",
        icon: "lifepreserver.fill",
        color: .stsDanger,
        category: "Rescue"
    )
]

private let quickPrompts = [
    "Can I afford ₹500?",
    "Food spend this week?",
    "Pace check",
    "Where to cut back?",
    "Show bills due"
]

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp = Date()
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timestamp)
    }
}

#Preview {
    ChatView()
}
