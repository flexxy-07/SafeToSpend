import Foundation

/// Centralized API client for SafeToSpend backend
actor APIClient {
    static let shared = APIClient()
    
    private let baseURL = "https://safetospend-api.onrender.com"
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    // MARK: - Generic Request
    
    private func request<T: Decodable>(
        _ method: String,
        path: String,
        body: (any Encodable)? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(statusCode: httpResponse.statusCode, body: errorBody)
        }
        
        return try decoder.decode(T.self, from: data)
    }
    
    private func requestVoid(
        _ method: String,
        path: String,
        body: (any Encodable)? = nil,
        headers: [String: String] = [:]
    ) async throws {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(statusCode: httpResponse.statusCode, body: errorBody)
        }
    }
    
    // MARK: - Onboarding
    
    func completeOnboarding(_ req: OnboardingCompleteRequest) async throws {
        let _: [String: AnyCodable] = try await request("POST", path: "/v1/onboarding/complete", body: req)
    }
    
    // MARK: - Today
    
    func getToday() async throws -> TodayResponse {
        try await request("GET", path: "/v1/today")
    }
    
    // MARK: - Expenses
    
    func previewExpense(_ req: ExpensePreviewRequest) async throws -> ExpensePreviewResponse {
        try await request("POST", path: "/v1/expenses/preview", body: req)
    }
    
    func createExpense(_ req: ExpenseCreateRequest, idempotencyKey: String? = nil) async throws -> ExpenseResponse {
        var headers: [String: String] = [:]
        if let key = idempotencyKey {
            headers["Idempotency-Key"] = key
        }
        return try await request("POST", path: "/v1/expenses", body: req, headers: headers)
    }
    
    func listExpenses() async throws -> [ExpenseResponse] {
        try await request("GET", path: "/v1/expenses")
    }
    
    func voidExpense(_ expenseId: String) async throws {
        try await requestVoid("PATCH", path: "/v1/expenses/\(expenseId)/void")
    }
    
    // MARK: - Bills
    
    func listBills() async throws -> [BillResponse] {
        try await request("GET", path: "/v1/bills")
    }
    
    func createBill(_ req: BillCreateRequest) async throws -> BillResponse {
        try await request("POST", path: "/v1/bills", body: req)
    }
    
    func markBillPaid(_ billId: String) async throws {
        try await requestVoid("POST", path: "/v1/bills/\(billId)/mark-paid")
    }
    
    // MARK: - AI Agent
    
    func askSafe(_ message: String) async throws -> AskSafeResponse {
        try await request("POST", path: "/v1/agents/ask", body: AskSafeRequest(message: message))
    }
    
    func getRescuePlan() async throws -> AskSafeResponse {
        try await request("POST", path: "/v1/agents/rescue-plan")
    }
    
    // MARK: - Proposals
    
    func listProposals() async throws -> [ProposalResponse] {
        try await request("GET", path: "/v1/proposals")
    }
    
    func confirmProposal(_ proposalId: String) async throws {
        try await requestVoid("POST", path: "/v1/proposals/\(proposalId)/confirm")
    }
    
    func rejectProposal(_ proposalId: String) async throws {
        try await requestVoid("POST", path: "/v1/proposals/\(proposalId)/reject")
    }
    
    // MARK: - Insights
    
    func getInsights() async throws -> InsightsResponse {
        try await request("GET", path: "/v1/insights")
    }
    
    // MARK: - Data Management
    
    func exportData() async throws -> [String: AnyCodable] {
        try await request("POST", path: "/v1/data/export")
    }
    
    func resetData() async throws {
        try await requestVoid("DELETE", path: "/v1/account/data")
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, body: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .httpError(let code, let body):
            return "Server error (\(code)): \(body)"
        }
    }
}

// MARK: - Type-Erased Encodable

private struct AnyEncodable: Encodable {
    let wrappedValue: any Encodable
    
    init(_ wrappedValue: any Encodable) {
        self.wrappedValue = wrappedValue
    }
    
    func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}
