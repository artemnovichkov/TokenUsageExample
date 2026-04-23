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
            let instructionsTokenCount = try await model.tokenCount(for: instructions)
            print(instructionsTokenCount, model.formattedPercent(tokenCount: instructionsTokenCount, contextSize: contextSize))

            let prompt = Prompt("Generate a haiku about Swift")
            let promptTokenCount = try await model.tokenCount(for: prompt)
            print(promptTokenCount, model.formattedPercent(tokenCount: promptTokenCount, contextSize: contextSize))

            let session = LanguageModelSession(model: model,
                                               tools: tools,
                                               instructions: instructions)

            let response = try await session.respond(to: prompt)
            print(response.content)

            let transcriptTokenCount = try await model.tokenCount(for: session.transcript)
            print(transcriptTokenCount, model.formattedPercent(tokenCount: transcriptTokenCount, contextSize: contextSize))
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

extension SystemLanguageModel {
    func percent(tokenCount: Int, contextSize: Int) -> Float {
        guard contextSize > 0 else { return 0 }
        return Float(tokenCount) / Float(contextSize)
    }

    func formattedPercent(tokenCount: Int, contextSize: Int) -> String {
        percent(tokenCount: tokenCount, contextSize: contextSize)
            .formatted(.percent.precision(.fractionLength(0)).rounded(rule: .down))
    }
}
