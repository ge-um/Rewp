//
//  SubtitleService.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import Foundation
import RxSwift
import OSLog

final class SubtitleService {
    private let videoRepository: VideoRepository

    init(videoRepository: VideoRepository) {
        self.videoRepository = videoRepository
    }

    func downloadSubtitle(url: String) -> Single<SubtitleTrack> {
        return videoRepository.downloadSubtitle(subtitlePath: url)
            .map { [weak self] content in
                guard let self = self else {
                    throw NSError(domain: "SubtitleService deallocated", code: -1)
                }

                Logger.video.debug("WebVTT content received - length: \(content.count)")
                Logger.video.debug("First 500 chars: \(String(content.prefix(500)))")

                let subtitles = self.parseWebVTT(content: content)
                Logger.video.debug("Parsed \(subtitles.count) subtitle entries")

                return SubtitleTrack(
                    language: "ko",
                    displayName: "한국어",
                    subtitles: subtitles
                )
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

        Logger.video.debug("Total lines: \(lines.count)")

        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            if line.contains("-->") {
                let times = line.components(separatedBy: "-->")
                guard times.count == 2,
                      let startTime = parseTime(times[0].trimmingCharacters(in: .whitespaces)),
                      let endTime = parseTime(times[1].trimmingCharacters(in: .whitespaces)) else {
                    Logger.video.debug("Failed to parse time from: \(line)")
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

        if components.count == 3 {
            let hours = Double(components[0]) ?? 0
            let minutes = Double(components[1]) ?? 0
            let secondsAndMillis = components[2].components(separatedBy: ".")
            let seconds = Double(secondsAndMillis[0]) ?? 0
            let millis = secondsAndMillis.count > 1 ? (Double(secondsAndMillis[1]) ?? 0) / 1000.0 : 0

            return hours * 3600 + minutes * 60 + seconds + millis
        } else if components.count == 2 {
            let minutes = Double(components[0]) ?? 0
            let secondsAndMillis = components[1].components(separatedBy: ".")
            let seconds = Double(secondsAndMillis[0]) ?? 0
            let millis = secondsAndMillis.count > 1 ? (Double(secondsAndMillis[1]) ?? 0) / 1000.0 : 0

            return minutes * 60 + seconds + millis
        }

        return nil
    }
}
