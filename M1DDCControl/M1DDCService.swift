import Foundation

enum M1DDCError: LocalizedError {
    case executableNotFound
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .executableNotFound:
            return "m1ddc not found"
        case .commandFailed(let message):
            return message
        }
    }
}

final class M1DDCService {
    private let executablePath = "/opt/homebrew/Cellar/m1ddc/1.2.0/bin/m1ddc"

    private func run(_ arguments: [String]) throws -> String {
        guard FileManager.default.fileExists(atPath: executablePath) else {
            throw M1DDCError.executableNotFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = String(data: outputData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let error = String(data: errorData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard process.terminationStatus == 0 else {
            throw M1DDCError.commandFailed(error.isEmpty ? output : error)
        }

        return output
    }

    func listDisplays() throws -> String {
        try run(["display", "list"])
    }

    func getBrightness(displayID: Int) throws -> String {
        try run(["display", "\(displayID)", "get", "luminance"])
    }

    func setBrightness(displayID: Int, value: Int) throws -> String {
        try run(["display", "\(displayID)", "set", "luminance", "\(value)"])
    }
}
