import Foundation

enum ExamSafeModeCaptureSchedule {
    static func offsets(durationSeconds: Int, maxCaptures: Int = 20) -> [Int] {
        let duration = max(durationSeconds, 1)
        let captures = max(1, min(maxCaptures, 20))
        let interval = Double(duration) / Double(captures)

        return (0..<captures).map { index in
            guard index > 0 else { return 0 }
            let lower = Double(index) * interval
            let jitterStart = lower + interval * 0.22
            let jitterEnd = lower + interval * 0.78
            let value = Double.random(in: jitterStart...jitterEnd)
            return min(duration, max(1, Int(value.rounded())))
        }
        .sorted()
    }
}
