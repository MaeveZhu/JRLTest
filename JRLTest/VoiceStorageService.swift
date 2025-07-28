import Foundation

protocol VoiceStorageService {
    func uploadVoiceRecording(fileURL: URL, metadata: [String: Any], completion: @escaping (Result<URL, Error>) -> Void)
} 