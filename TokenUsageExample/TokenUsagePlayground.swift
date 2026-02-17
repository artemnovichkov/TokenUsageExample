//
//  Created by Artem Novichkov on 17.02.2026.
//

import Playgrounds
import FoundationModels
import Foundation

#Playground {
    Task {
        do {
            let model = SystemLanguageModel.default
            let contextSize = try await model.contextSize
            print("Context size", contextSize)

            let instructions = Instructions("You're a helpful assistant that generates haiku.")
            let tools = [MoodTool()]
            let instructionsTokenUsage = try await model.tokenUsage(for: instructions,
                                                                    tools: tools)
            print(instructionsTokenUsage.tokenCount, instructionsTokenUsage.formattedPercent(ofContextSize: contextSize))

            let prompt = Prompt("Generate a haiku about Swift")
            let promptTokenUsage = try await model.tokenUsage(for: prompt)
            print(promptTokenUsage.tokenCount, promptTokenUsage.formattedPercent(ofContextSize: contextSize))

            let session = LanguageModelSession(model: model,
                                               tools: tools,
                                               instructions: instructions)

            let response = try await session.respond(to: prompt)
            print(response.content)

            let transcriptTokenUsage = try await model.tokenUsage(for: session.transcript)
            print(transcriptTokenUsage.tokenCount, transcriptTokenUsage.formattedPercent(ofContextSize: contextSize))
        } catch {
            print(error)
        }
    }
}

@Generable
enum Mood: String, CaseIterable {
    case happy, sad, thoughtful, excited, calm
}

struct MoodTool: Tool {
    let name = "generateMood"
    let description = "Generates a mood for haiku"

    @Generable
    struct Arguments {}

    func call(arguments: Arguments) async throws -> GeneratedContent {
        GeneratedContent(properties: ["mood": Mood.allCases.randomElement()])
    }
}

extension SystemLanguageModel.TokenUsage {
    func percent(ofContextSize contextSize: Int) -> Float {
        guard contextSize > 0 else { return 0 }
        return Float(tokenCount) / Float(contextSize)
    }

    func formattedPercent(ofContextSize contextSize: Int) -> String {
        percent(ofContextSize: contextSize)
            .formatted(.percent.precision(.fractionLength(0)).rounded(rule: .down))
    }
}
