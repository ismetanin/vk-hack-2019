//
//  FeedbackService.swift
//  SunCity
//
//  Created by i.smetanin on 29/09/2019.
//  Copyright © 2019 i.smetanin. All rights reserved.
//

import Foundation
import NodeKit

enum UserType: Int, Codable {
    case mentor
    case psychologist
}

struct Comment: Codable {
    let dateString: String
    let image: String
    let isMe: Bool
    let name: String
    let userId: String
    let text: String

    var date: Date {
        return Formatter.iso8601.date(from: dateString) ?? Date()
    }

    enum CodingKeys: String, CodingKey {
        case dateString = "Date"
        case image = "Image"
        case isMe = "IsMe"
        case name = "Name"
        case userId = "UserID"
        case text = "text"
    }
}

struct Feedback: Codable {
    let audio: String
    let comments: [Comment]?
    let id: String
    let images: [String]
    let text: String
    let userId: String
    let dateString: String

    var date: Date {
        return Formatter.iso8601.date(from: dateString) ?? Date()
    }

    enum CodingKeys: String, CodingKey {
        case audio = "Audio"
        case comments = "Comments"
        case id = "ID"
        case images = "Images"
        case text = "Text"
        case userId = "UserID"
        case dateString = "Date"
    }
}

struct GetAllFeedbackRawResponse: Codable {
    let user: User
    let payload: [Feedback]
}

final class FeedbackService {

    func getAll(onSuccess: @escaping (GetAllFeedbackRawResponse) -> Void, onError: @escaping () -> Void) {
        let url = URL(string: "http://demo6.alpha.vkhackathon.com:8844/feedback")!
        var request = URLRequest(url: url)
        request.addValue(UserDefaults.standard.token ?? "", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard
                    let data = data,
                    let response = response as? HTTPURLResponse,
                    error == nil,
                    (200 ... 299) ~= response.statusCode,
                    let responseData = try? JSONSerialization.jsonObject(
                        with: data,
                        options: .allowFragments
                    ) as? [String: Any]
                else {
                    onError()
                    return
                }
                print(responseData)
                let rawResponse: GetAllFeedbackRawResponse = try! JSONDecoder().decode(
                    GetAllFeedbackRawResponse.self,
                    from: data
                )
                onSuccess(rawResponse)
            }
        }

        task.resume()
    }

    struct TestData: DTOConvertible, RawMappable {

        typealias DTO = TestData

        typealias Raw = [String: Data]

        let data: [String: Data]

        func toDTO() throws -> TestData {
            return self
        }

        func toRaw() throws -> [String : Data] {
            return self.data
        }

        static func from(dto: TestData) throws -> TestData {
            return .init(data: dto.data)
        }

        static func from(raw: [String : Data]) throws -> TestData {
            return .init(data: raw)
        }
    }

    func postForm(text: String, audio: URL?, photos: [Data]) -> Observer<Void> {

        let data = TestData(data: [

            "text": Data(text.utf8)
        ])

        var files = [String: MultipartFileProvider]()

        for (index, item) in photos.enumerated() {
            files["photo\(index)"] = .data(data: item, filename: "photo\(index).png", mimetype: " image/png")
        }

        if let audio = audio {
            files["audio"] = .url(url: audio)
        }

        return UrlChainsBuilder().default(with: .init(method: .post, route: "http://demo6.alpha.vkhackathon.com:8844/feedback/comment", metadata: ["Authorization": UserDefaults.standard.token ?? ""])).process(MultipartModel(payloadModel: data, files: files)).map { (json: Json) in
            return ()
        }
    }

    func sendMessage(text: String, formId: String) -> Observer<Void> {
        return UrlChainsBuilder().default(with: .init(method: .post, route: "http://demo6.alpha.vkhackathon.com:8844/feedback/comment/\(formId)", metadata: ["Authorization": UserDefaults.standard.token ?? ""])).process(["text": text])
    }

}
