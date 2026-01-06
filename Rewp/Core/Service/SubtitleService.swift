//
//  SubtitleService.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import Foundation
import RxSwift

final class SubtitleService {
    func downloadSubtitle(url: String) -> Single<SubtitleTrack> {
        return Single.create { single in
            guard let subtitleUrl = URL(string: url) else {
                single(.failure(NSError(domain: "Invalid subtitle URL", code: -1)))
                return Disposables.create()
            }

            let task = URLSession.shared.dataTask(with: subtitleUrl) { data, response, error in
                if let error = error {
                    single(.failure(error))
                    return
                }

                guard let data = data,
                      let content = String(data: data, encoding: .utf8) else {
                    single(.failure(NSError(domain: "Failed to decode subtitle", code: -1)))
                    return
                }

                let subtitles = self.parseWebVTT(content: content)
                let track = SubtitleTrack(
                    language: "ko",
                    displayName: "한국어",
                    subtitles: subtitles
                )

                single(.success(track))
            }

            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func getCurrentSubtitle(track: SubtitleTrack, currentTime: TimeInterval) -> String? {
        return track.subtitles.first { subtitle in
            currentTime >= subtitle.startTime && currentTime <= subtitle.endTime
        }?.text
    }

    private func parseWebVTT(content: String) -> [Subtitle] {
        var subtitles: [Subtitle] = []
        let lines = content.components(separatedBy: .newlines)

        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            if line.contains("-->") {
                let times = line.components(separatedBy: "-->")
                guard times.count == 2,
                      let startTime = parseTime(times[0].trimmingCharacters(in: .whitespaces)),
                      let endTime = parseTime(times[1].trimmingCharacters(in: .whitespaces)) else {
                    i += 1
                    continue
                }

                i += 1
                var text = ""
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).isEmpty {
                    text += lines[i] + "\n"
                    i += 1
                }

                let subtitle = Subtitle(
                    startTime: startTime,
                    endTime: endTime,
                    text: text.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                subtitles.append(subtitle)
            }

            i += 1
        }

        return subtitles
    }

    private func parseTime(_ timeString: String) -> TimeInterval? {
        let components = timeString.components(separatedBy: ":")
        guard components.count == 3 else { return nil }

        let hours = Double(components[0]) ?? 0
        let minutes = Double(components[1]) ?? 0
        let secondsAndMillis = components[2].components(separatedBy: ".")
        let seconds = Double(secondsAndMillis[0]) ?? 0
        let millis = secondsAndMillis.count > 1 ? (Double(secondsAndMillis[1]) ?? 0) / 1000.0 : 0

        return hours * 3600 + minutes * 60 + seconds + millis
    }
}
