import Foundation

// MARK: - Request Models

struct OnboardingCompleteRequest: Codable {
    let startingBalancePaise: Int
    let cycleStartDate: String
    let cycleEndDate: String
    var safetyBufferPaise: Int?
    var savingsReservePaise: Int?
    var timezone: String?
    
    enum CodingKeys: String, CodingKey {
        case startingBalancePaise = "starting_balance_paise"
        case cycleStartDate = "cycle_start_date"
        case cycleEndDate = "cycle_end_date"
        case safetyBufferPaise = "safety_buffer_paise"
        case savingsReservePaise = "savings_reserve_paise"
        case timezone
    }
}

struct ExpensePreviewRequest: Codable {
    let rawInput: String
    
    enum CodingKeys: String, CodingKey {
        case rawInput = "raw_input"
    }
}

struct ExpenseCreateRequest: Codable {
    let amountPaise: Int
    var occurredOn: String?
    var description: String?
    var merchant: String?
    var category: String?
    var source: String?
    var sourceRef: String?
    
    enum CodingKeys: String, CodingKey {
        case amountPaise = "amount_paise"
        case occurredOn = "occurred_on"
        case description, merchant, category, source
        case sourceRef = "source_ref"
    }
}

struct BillCreateRequest: Codable {
    let name: String
    let amountPaise: Int
    let dueDate: String
    var cadence: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case amountPaise = "amount_paise"
        case dueDate = "due_date"
        case cadence
    }
}

struct AskSafeRequest: Codable {
    let message: String
}

// MARK: - Response Models

struct TodayResponse: Codable, Equatable {
    let cycleId: String
    let status: String
    let calculationVersion: String
    let dataRevision: Int
    let computedAt: String
    var currency: String = "INR"
    var amountUnit: String = "paise"
    let availableBalancePaise: Int
    let unpaidCommitmentsPaise: Int
    let remainingSavingsReservePaise: Int
    let safetyBufferPaise: Int
    let rawPoolPaise: Int
    let poolPaise: Int
    let shortfallPaise: Int
    let daysRemaining: Int
    let stsPaise: Int
    var forecast: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case cycleId = "cycle_id"
        case status
        case calculationVersion = "calculation_version"
        case dataRevision = "data_revision"
        case computedAt = "computed_at"
        case currency
        case amountUnit = "amount_unit"
        case availableBalancePaise = "available_balance_paise"
        case unpaidCommitmentsPaise = "unpaid_commitments_paise"
        case remainingSavingsReservePaise = "remaining_savings_reserve_paise"
        case safetyBufferPaise = "safety_buffer_paise"
        case rawPoolPaise = "raw_pool_paise"
        case poolPaise = "pool_paise"
        case shortfallPaise = "shortfall_paise"
        case daysRemaining = "days_remaining"
        case stsPaise = "sts_paise"
        case forecast
    }
    
    static func == (lhs: TodayResponse, rhs: TodayResponse) -> Bool {
        lhs.dataRevision == rhs.dataRevision && lhs.stsPaise == rhs.stsPaise
    }
}

struct ExpensePreviewResponse: Codable {
    let candidateAmountPaise: Int
    var candidateDescription: String?
    var candidateCategory: String?
    let confidence: Double
    var source: String?
    
    enum CodingKeys: String, CodingKey {
        case candidateAmountPaise = "candidate_amount_paise"
        case candidateDescription = "candidate_description"
        case candidateCategory = "candidate_category"
        case confidence, source
    }
}

struct ExpenseResponse: Codable, Identifiable {
    let id: String
    let cycleId: String
    let amountPaise: Int
    let occurredOn: String
    var description: String?
    var merchant: String?
    let category: String
    let source: String
    let status: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case cycleId = "cycle_id"
        case amountPaise = "amount_paise"
        case occurredOn = "occurred_on"
        case description, merchant, category, source, status
        case createdAt = "created_at"
    }
    
    var displayTitle: String {
        description ?? merchant ?? category.capitalized
    }
    
    var categoryIcon: String {
        switch category.lowercased() {
        case "food", "dining": return "🍽️"
        case "transport", "transportation": return "🚗"
        case "shopping": return "🛍️"
        case "entertainment": return "🎬"
        case "health", "medical": return "🏥"
        case "utilities": return "⚡"
        case "groceries": return "🛒"
        case "education": return "📚"
        case "travel": return "✈️"
        case "subscription": return "🔄"
        default: return "💸"
        }
    }
}

struct BillResponse: Codable, Identifiable {
    let id: String
    let cycleId: String
    let name: String
    let amountPaise: Int
    let dueDate: String
    let cadence: String
    let status: String
    var paidExpenseId: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case cycleId = "cycle_id"
        case name
        case amountPaise = "amount_paise"
        case dueDate = "due_date"
        case cadence, status
        case paidExpenseId = "paid_expense_id"
        case createdAt = "created_at"
    }
    
    var isPaid: Bool { status.lowercased() == "paid" }
    
    var billIcon: String {
        switch name.lowercased() {
        case let n where n.contains("rent"): return "🏠"
        case let n where n.contains("electric") || n.contains("power"): return "⚡"
        case let n where n.contains("water"): return "💧"
        case let n where n.contains("internet") || n.contains("wifi"): return "📡"
        case let n where n.contains("phone") || n.contains("mobile"): return "📱"
        case let n where n.contains("insurance"): return "🛡️"
        case let n where n.contains("netflix") || n.contains("streaming"): return "📺"
        case let n where n.contains("gym") || n.contains("fitness"): return "💪"
        default: return "📄"
        }
    }
}

struct InsightsResponse: Codable {
    let totalSpentPaise: Int
    let categoryBreakdown: [String: Int]
    let expensesCount: Int
    let loggingStreakDays: Int
    
    enum CodingKeys: String, CodingKey {
        case totalSpentPaise = "total_spent_paise"
        case categoryBreakdown = "category_breakdown"
        case expensesCount = "expenses_count"
        case loggingStreakDays = "logging_streak_days"
    }
}

struct AskSafeResponse: Codable {
    let text: String
    var whatIfCard: [String: AnyCodable]?
    var proposalDraft: [String: AnyCodable]?
    let source: String
    
    enum CodingKeys: String, CodingKey {
        case text
        case whatIfCard = "what_if_card"
        case proposalDraft = "proposal_draft"
        case source
    }
}

struct ProposalResponse: Codable, Identifiable {
    let id: String
    let proposalType: String
    let title: String
    let reason: String
    let status: String
    let expectedRevision: Int
    var before: [String: AnyCodable]?
    var after: [String: AnyCodable]?
    var impactPreview: [String: AnyCodable]?
    let expiresAt: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case proposalType = "proposal_type"
        case title, reason, status
        case expectedRevision = "expected_revision"
        case before, after
        case impactPreview = "impact_preview"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
    }
}

// MARK: - AnyCodable Helper (for dynamic JSON fields)
struct AnyCodable: Codable, Equatable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intVal as Int: try container.encode(intVal)
        case let doubleVal as Double: try container.encode(doubleVal)
        case let boolVal as Bool: try container.encode(boolVal)
        case let stringVal as String: try container.encode(stringVal)
        case let dictVal as [String: AnyCodable]: try container.encode(dictVal)
        case let arrayVal as [AnyCodable]: try container.encode(arrayVal)
        default: try container.encodeNil()
        }
    }
    
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        String(describing: lhs.value) == String(describing: rhs.value)
    }
}
