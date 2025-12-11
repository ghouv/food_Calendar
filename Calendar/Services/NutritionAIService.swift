import Foundation

final class NutritionAIService {

    private let session: URLSession
    private let apiKey: String

    init(session: URLSession = .shared, apiKey: String = AppConfig.openAIAPIKey) {
        self.session = session
        self.apiKey = apiKey
    }

    enum NutritionError: Error {
        case missingAPIKey
        case invalidResponse
        case decodingFailed
    }

    func fetchNutrition(
        for foodName: String,
        completion: @escaping (Result<NutritionInfo, Error>) -> Void
    ) {
        guard !apiKey.isEmpty, apiKey != "YOUR_API_KEY_HERE" else {
            completion(.failure(NutritionError.missingAPIKey))
            return
        }

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(NutritionError.invalidResponse))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        struct ChatRequest: Encodable {
            struct Message: Encodable {
                let role: String
                let content: String
            }

            let model: String
            let messages: [Message]
            let temperature: Double
            let max_completion_tokens: Int
        }

        let prompt = """
        You are a nutrition expert.

        For the Korean food name "\(foodName)", output ONLY four integers separated by commas in this exact order:

        calories (kcal), carbohydrates (g), protein (g), fat (g)

        Example output:
        530, 60, 20, 10

        If you are not sure, reply exactly:
        0, 0, 0, 0
        """

        let body = ChatRequest(
            model: "gpt-4.1-mini",
            messages: [
                .init(role: "user", content: prompt)
            ],
            temperature: 0.1,
            max_completion_tokens: 64
        )

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NutritionError.invalidResponse))
                }
                return
            }

            // Debug: raw response 보기
            if let raw = String(data: data, encoding: .utf8) {
                print("NutritionAI raw response:", raw)
            }

            struct ChatResponse: Decodable {
                struct Choice: Decodable {
                    struct Message: Decodable {
                        let content: String
                    }
                    let message: Message
                }
                let choices: [Choice]
            }

            do {
                let chat = try JSONDecoder().decode(ChatResponse.self, from: data)
                guard let content = chat.choices.first?.message.content else {
                    throw NutritionError.decodingFailed
                }

                // "530, 60, 20, 10" 같은 포맷에서 숫자 네 개 뽑기
                let numbers = content
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .compactMap { token -> Int? in
                        let digits = token.filter { "0123456789".contains($0) }
                        return Int(digits)
                    }

                guard numbers.count == 4 else {
                    throw NutritionError.decodingFailed
                }

                let info = NutritionInfo(
                    calories: numbers[0],
                    carbs: numbers[1],
                    protein: numbers[2],
                    fat: numbers[3]
                )

                DispatchQueue.main.async {
                    completion(.success(info))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }

        task.resume()
    }
}
