import SwiftUI

struct ExamKeyboardModePicker: View {
    let selectedMode: ExamAnswerInputMode
    let onSelect: (ExamAnswerInputMode) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ExamAnswerInputMode.allCases) { mode in
                Button {
                    onSelect(mode)
                } label: {
                    Text(mode.title)
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(selectedMode == mode ? Color(hex: "7257F4") : Color(hex: "EEF1F7"))
                        .foregroundStyle(selectedMode == mode ? .white : Color(hex: "687083"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ExamAnswerKeyboard: View {
    let mode: ExamAnswerInputMode
    var containerWidth: CGFloat = UIScreen.main.bounds.width
    var showsDraft = true
    let onModeSelect: (ExamAnswerInputMode) -> Void
    let onDraft: () -> Void
    let onInput: (String) -> Void
    let onDelete: () -> Void
    let onClear: () -> Void
    let onMoveCursorRight: () -> Void

    @State private var isUppercased = false
    @State private var usesOpeningQuote = true

    var body: some View {
        Group {
            switch mode {
            case .russian:
                textKeyboard(rows: russianRows)
            case .english:
                textKeyboard(rows: englishRows)
            case .math:
                mathKeyboard
            }
        }
    }

    private var russianRows: [[String]] {
        [
            ["й", "ц", "у", "к", "е", "н", "г", "ш", "щ", "з"],
            ["ф", "ы", "в", "а", "п", "р", "о", "л", "д"],
            ["я", "ч", "с", "м", "и", "т", "ь", "б", "ю"]
        ]
    }

    private var englishRows: [[String]] {
        [
            ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
            ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
            ["z", "x", "c", "v", "b", "n", "m"]
        ]
    }

    private var punctuationRow: [String] {
        ["«»", "—", "!", "?", "(", ")", ":", ";", ",", "."]
    }

    private var mathRows: [[String]] {
        var rows = [
            ["sin", "cos", "tg", "ctg", "asin", "acos", "atg", "actg", "log"],
            ["+", "1", "2", "3", "≤", "≥", "°", "CE"],
            ["-", "4", "5", "6", "<", ">", "()", "Delete"],
            ["×", "7", "8", "9", "√", "aⁿ", "∪", "∞"],
            ["\\", ".", "0", "=", "⏎", "π", "абв", "Черн"]
        ]
        if !showsDraft {
            rows[4].removeAll { $0 == "Черн" }
        }
        return rows
    }

    private var mathSymbolMap: [String: String] {
        [
            "sin": "\\sin", "cos": "\\cos", "tg": "\\tan", "ctg": "\\cot",
            "asin": "\\arcsin", "acos": "\\arccos", "atg": "\\arctan", "actg": "\\operatorname{arccot}",
            "<": "<", ">": ">",
            "+": "+", "1": "1", "2": "2", "3": "3", "≤": "\\leq ", "≥": "\\geq ", "°": "^\\circ", "CE": "CE",
            "-": "-", "4": "4", "5": "5", "6": "6", "Delete": "Delete",
            "×": "*", "7": "7", "8": "8", "9": "9", "√": "\\sqrt[", "aⁿ": "^{", "log": "log_{", "∪": "\\cup ", "π": "\\pi",
            "\\": "\\frac{", ".": ".", "0": "0", "=": "=", "⏎": "ENTER", "∞": "\\infty "
        ]
    }

    private var spacing: CGFloat {
        containerWidth < 500 ? 5 : 4
    }

    private var containerPadding: CGFloat {
        containerWidth < 500 ? 10 : 8
    }

    private var keyWidth: CGFloat {
        let totalSpacing = spacing * 9
        let available = keyboardWidth - totalSpacing - containerPadding * 2
        return max(24, floor(available / 10))
    }

    private var keyHeight: CGFloat {
        min(42, keyWidth * 1.08)
    }

    private var keyboardWidth: CGFloat {
        min(max(containerWidth - 24, 280), 430)
    }

    private var mathKeyboard: some View {
        VStack(spacing: spacing) {
            mathKeyboardRow(keys: mathRows[0], numberOfButtons: 9)
            mathKeyboardRow(keys: mathRows[1], numberOfButtons: 8)
            mathKeyboardRow(keys: mathRows[2], numberOfButtons: 8)
            mathKeyboardRow(keys: mathRows[3], numberOfButtons: 8)
            mathKeyboardRow(keys: mathRows[4], numberOfButtons: 8)
        }
        .padding(containerPadding)
        .background(keyboardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "E4E7F0"), lineWidth: 1)
        }
        .shadow(color: accentColor.opacity(0.10), radius: 18, x: 0, y: 8)
        .frame(maxWidth: keyboardWidth)
    }

    private func mathKeyboardRow(keys: [String], numberOfButtons: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(keys, id: \.self) { key in
                mathKeyboardButton(key, width: flexibleMathWidth(for: numberOfButtons))
            }
        }
    }

    private func mathKeyboardButton(_ title: String, width: CGFloat) -> some View {
        Button {
            switch title {
            case "Delete":
                onDelete()
            case "CE":
                onClear()
            case "абв":
                onModeSelect(.russian)
            case "EN":
                onModeSelect(.english)
            case "Черн":
                onDraft()
            case "⏎":
                onMoveCursorRight()
            case "()":
                onInput("(")
            default:
                if let symbol = mathSymbolMap[title] {
                    onInput(symbol)
                }
            }
        } label: {
            if title == "Delete" {
                Image(systemName: "delete.left")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: width, height: mathKeyHeight)
                    .background(Color(hex: "EF4444"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                mathButtonLabel(title: title, width: width)
            }
        }
        .buttonStyle(.plain)
    }

    private func mathButtonLabel(title: String, width: CGFloat) -> some View {
        Group {
            if title == "Черн" {
                Image(systemName: "pencil.tip")
                    .font(.system(size: 15, weight: .bold))
            } else if title == "абв" {
                Text("абв")
                    .font(.system(size: 13, weight: .heavy))
            } else {
                Text(title)
                    .font(.system(size: 14, weight: isMathAccent(title) ? .heavy : .semibold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
        .frame(width: width, height: mathKeyHeight)
        .background(mathKeyBackground(title))
        .foregroundColor(mathKeyForeground(title))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func flexibleMathWidth(for numberOfButtons: Int) -> CGFloat {
        let totalSpacing = CGFloat(numberOfButtons - 1) * spacing
        return (keyboardWidth - totalSpacing - containerPadding * 2) / CGFloat(numberOfButtons)
    }

    private func textKeyboard(rows: [[String]]) -> some View {
        VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                ForEach(punctuationRow, id: \.self) { key in
                    textKeyButton(title: key, width: textRowKeyWidth(itemCount: punctuationRow.count), accent: true) {
                        if key == "«»" {
                            onInput(usesOpeningQuote ? "«" : "»")
                            usesOpeningQuote.toggle()
                        } else {
                            onInput(key)
                        }
                    }
                }
            }

            ForEach(rows.indices, id: \.self) { rowIndex in
                let rowItemCount = rows[rowIndex].count + (rowIndex == 2 ? 2 : 0)
                let rowKeyWidth = textRowKeyWidth(itemCount: rowItemCount)

                HStack(spacing: spacing) {
                    if rowIndex == 2 {
                        textActionKey(systemName: "shift", width: rowKeyWidth) {
                            isUppercased.toggle()
                        }
                    }

                    ForEach(rows[rowIndex], id: \.self) { key in
                        textKeyButton(title: displayKey(key), width: rowKeyWidth) {
                            onInput(displayKey(key))
                        }
                    }

                    if rowIndex == 2 {
                        textActionKey(systemName: "delete.left", width: rowKeyWidth) {
                            onDelete()
                        }
                    }
                }
            }

            HStack(spacing: spacing) {
                if showsDraft {
                    textActionKey(systemName: "pencil.tip") {
                        onDraft()
                    }
                }
                textActionKey(title: "∑") {
                    onModeSelect(.math)
                }
                textActionKey(title: mode == .russian ? "EN" : "RU") {
                    onModeSelect(mode == .russian ? .english : .russian)
                }
                textSpaceKey()
                textActionKey(title: "↵") {
                    onInput("\n")
                }
                textActionKey(systemName: "trash.fill", background: Color(hex: "EF4444"), foreground: .white) {
                    onClear()
                }
            }
        }
        .padding(containerPadding)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(keyboardBackground)
                .shadow(color: accentColor.opacity(0.10), radius: 18, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "E4E7F0"), lineWidth: 1)
        )
        .frame(maxWidth: keyboardWidth)
    }

    private func textKeyButton(title: String, width: CGFloat? = nil, accent: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: keyWidth * 0.43, weight: accent ? .semibold : .medium))
                .frame(width: width ?? keyWidth, height: keyHeight)
                .background(accent ? keyAccentSoft : keyFill)
                .foregroundColor(accent ? accentColor : keyText)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func textSmallKey(_ value: String) -> some View {
        Button {
            onInput(value)
        } label: {
            Text(value)
                .font(.system(size: keyWidth * 0.4))
                .frame(width: keyWidth, height: keyHeight)
                .background(keyAccentSoft)
                .foregroundColor(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func textSpaceKey() -> some View {
        Button {
            onInput(" ")
        } label: {
            Text("Пробел")
                .font(.system(size: keyWidth * 0.34, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: keyHeight)
                .background(keyFill)
                .foregroundColor(keyText)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .layoutPriority(1)
    }

    private func textActionKey(
        systemName: String,
        width: CGFloat? = nil,
        background: Color = Color(hex: "F4F0FF"),
        foreground: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: keyWidth * 0.45, weight: .semibold))
                .frame(width: width ?? keyWidth * 1.3, height: keyHeight)
                .background(background)
                .foregroundColor(foreground ?? accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func textActionKey(
        title: String,
        background: Color = Color(hex: "F4F0FF"),
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: keyWidth * 0.45, weight: .bold))
                .frame(width: keyWidth * 1.3, height: keyHeight)
                .background(background)
                .foregroundColor(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func displayKey(_ key: String) -> String {
        isUppercased ? key.uppercased() : key
    }

    private func textRowKeyWidth(itemCount: Int) -> CGFloat {
        let count = max(CGFloat(itemCount), 1)
        let totalSpacing = spacing * (count - 1)
        let available = keyboardWidth - containerPadding * 2 - totalSpacing
        return max(22, floor(available / count))
    }

    private var mathKeyHeight: CGFloat { 40 }
    private var accentColor: Color { Color(hex: "7257F4") }
    private var keyText: Color { Color(hex: "20242D") }
    private var keyFill: Color { Color.white }
    private var keyAccentSoft: Color { Color(hex: "F4F0FF") }
    private var keyboardBackground: Color { Color(hex: "F8FAFF") }

    private func isMathAccent(_ title: String) -> Bool {
        ["⏎", "абв", "EN", "Черн"].contains(title)
    }

    private func mathKeyBackground(_ title: String) -> Color {
        switch title {
        case "⏎", "абв", "EN", "Черн":
            keyAccentSoft
        case "CE":
            Color(hex: "FFF4E6")
        default:
            keyFill
        }
    }

    private func mathKeyForeground(_ title: String) -> Color {
        switch title {
        case "CE":
            Color(hex: "F59E0B")
        case "⏎", "абв", "EN", "Черн":
            accentColor
        default:
            keyText
        }
    }
}
