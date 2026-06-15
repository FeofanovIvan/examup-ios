import Foundation

struct ExamLatexInputEngine {
    private var left: [String] = []
    private var right: [String] = []
    private var isTextBlockOpen = false

    private let roundBracketOpenings = ["\\sqrt(", "(", "log_{"]
    private let curlyBracketOpenings = ["\\sqrt{", "^{", "\\frac{", "\\text{"]
    private let closingSymbols = [")", "}", "}{", "}(", "]", "]{"]
    private let openingSymbols = [
        "sin", "cos", "\\sqrt(", "(", "log_{", "\\sqrt{", "}{", "}(", "^{", "\\frac{", "\\text{",
        "tg", "ctg", "arcs", "arcc", "arct", "arcct", ""
    ]
    private let numbers = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "^\\circ", "\\cup", "\\pi", "\\infty"]
    private let arithmeticWithoutMinus = ["+", "*", "\\times ", "^{"]
    private let signs = ["+", "-", "*", "\\times ", "^\\circ", "\\cup"]
    private let rootBracketOpenings = ["\\sqrt["]
    private let trigFunctions = ["\\sin", "\\cos", "\\tan", "\\cot", "\\arcsin", "\\arccos", "\\arctan", "\\operatorname{arccot}"]
    private let degreeSymbol = "^\\circ"

    var isEmpty: Bool {
        left.isEmpty && right.isEmpty
    }

    var latexWithCursor: String {
        left.joined() + "\\lceil" + right.reversed().joined()
    }

    var latexForRendering: String {
        if keepsActiveFormulaOnOneLine {
            return left.joined() + "\\lceil" + right.reversed().joined()
        }

        return renderableLatex(from: left) + "\\lceil" + renderableLatex(from: right.reversed())
    }

    var latexForSaving: String {
        left.joined() + right.reversed().joined()
    }

    var keepsActiveFormulaOnOneLine: Bool {
        !isTextBlockOpen && !right.isEmpty
    }

    mutating func restore(_ latex: String) {
        left = latex.isEmpty ? [] : [latex]
        right = []
        isTextBlockOpen = false
    }

    mutating func clear() {
        left = []
        right = []
        isTextBlockOpen = false
    }

    mutating func delete() {
        guard !left.isEmpty else { return }

        let lastItem = left.removeLast()
        guard let lastChar = lastItem.last else { return }

        if lastItem == "}{" || lastItem == "}(" || lastChar == "}" || lastChar == ")" {
            right.append(lastItem)
        } else if lastItem == "\\frac{" || lastItem == "log_{" {
            if right.count >= 2 {
                right.removeLast()
                right.removeLast()
            }
        } else if lastChar == "{" || lastChar == "(" {
            if !right.isEmpty {
                right.removeLast()
            }
        }
    }

    mutating func moveCursorRight() {
        guard !right.isEmpty else { return }
        left.append(right.removeLast())
    }

    mutating func insertMathSymbol(_ symbol: String) {
        closeTextIfNeeded()
        addSymbol(symbol)
    }

    mutating func insertText(_ text: String) {
        openTextIfNeeded()
        left.append(Self.escapeTextValue(text))
    }

    mutating func insertLineBreak() {
        if isTextBlockOpen {
            closeTextIfNeeded()
            addSymbol("\\\\")
            openTextIfNeeded()
        } else {
            addSymbol("\\\\")
        }
    }

    mutating func openTextIfNeeded() {
        guard !isTextBlockOpen else { return }
        addSymbol("\\text{")
        isTextBlockOpen = true
    }

    mutating func closeTextIfNeeded() {
        guard isTextBlockOpen else { return }
        if let closingIndex = right.lastIndex(of: "}") {
            let suffix = right.suffix(from: closingIndex)
            right.removeSubrange(closingIndex..<right.endIndex)
            left.append(contentsOf: suffix.reversed())
        }
        isTextBlockOpen = false
    }

    private mutating func addSymbol(_ symbol: String) {
        guard !hasInsertionViolation(symbol) else { return }

        if let last = left.last, last == ">", symbol == "=" {
            left[left.count - 1] = "\\geq "
        } else if let last = left.last, last == "<", symbol == "=" {
            left[left.count - 1] = "\\leq "
        } else if symbol == "}" {
            if let fromRight = right.last {
                left.append(fromRight)
            }
        } else {
            left.append(symbol)
        }

        handleBrackets(symbol)
        handleRootBrackets(symbol)
    }

    private mutating func handleBrackets(_ symbol: String) {
        if roundBracketOpenings.contains(symbol) {
            right.append(")")
            if symbol == "log_{" {
                right.append("}(")
            }
        } else if curlyBracketOpenings.contains(symbol) {
            right.append("}")
            if symbol == "\\frac{" {
                right.append("}{")
            }
        } else if symbol == ")" || symbol == "}" {
            if !right.isEmpty {
                right.removeLast()
            }
        }

        if trigFunctions.contains(symbol) {
            left.append("(")
            right.append(")")
        }
    }

    private mutating func handleRootBrackets(_ symbol: String) {
        if rootBracketOpenings.contains(symbol) {
            right.append("}")
            right.append("]{")
        }
    }

    private mutating func hasInsertionViolation(_ symbol: String) -> Bool {
        let lastSymbol = left.last ?? ""
        let nextSymbol = right.last ?? ""

        if left.isEmpty && startsWithBinaryOperator(symbol) {
            return true
        }

        if symbol == degreeSymbol && !canAttachDegree(to: lastSymbol) {
            return true
        }

        if lastSymbol == degreeSymbol && startsOperand(symbol) {
            return true
        }

        if symbol == "^{" && !canAttachPower(to: lastSymbol) {
            return true
        }

        if isTemplateSymbol(symbol) && shouldBlockTemplateAfter(lastSymbol) {
            return true
        }

        if openingSymbols.contains(lastSymbol) && arithmeticWithoutMinus.contains(symbol) && !trigFunctions.contains(lastSymbol) {
            return true
        }

        if !numbers.contains(lastSymbol) && symbol == "." {
            return true
        }

        if lastSymbol == "." && !numbers.contains(symbol) {
            return true
        }

        if signs.contains(lastSymbol) && signs.contains(symbol) {
            return true
        }

        if signs.contains(lastSymbol) && symbol == "^{" {
            return true
        }

        if lastSymbol == "}" && symbol == "^{" {
            return true
        }

        if openingSymbols.contains(lastSymbol) && closingSymbols.contains(symbol) && !trigFunctions.contains(lastSymbol) {
            return true
        }

        if symbol == ")" && nextSymbol != ")" {
            return true
        }

        if symbol == "}" && !closingSymbols.contains(nextSymbol) {
            return true
        }

        if trigFunctions.contains(lastSymbol) && symbol == "^{" {
            return false
        }

        if lastSymbol == "\\pi" && numbers.contains(symbol) {
            left.append("*")
            return false
        }

        return false
    }

    private func startsWithBinaryOperator(_ symbol: String) -> Bool {
        symbol == "+" || symbol == "*" || symbol == "\\times " || symbol == "=" || symbol == degreeSymbol || symbol == "\\cup"
    }

    private func startsOperand(_ symbol: String) -> Bool {
        numbers.contains(symbol)
            || trigFunctions.contains(symbol)
            || symbol == "\\sqrt["
            || symbol == "\\frac{"
            || symbol == "log_{"
            || symbol == "("
    }

    private func canAttachDegree(to symbol: String) -> Bool {
        symbol.count == 1 && symbol.first?.isNumber == true
    }

    private func canAttachPower(to symbol: String) -> Bool {
        if trigFunctions.contains(symbol) {
            return true
        }

        return (symbol.count == 1 && symbol.first?.isNumber == true)
            || symbol == ")"
            || symbol == "\\pi"
            || symbol == "\\infty "
    }

    private func isTemplateSymbol(_ symbol: String) -> Bool {
        symbol == "\\sqrt[" || symbol == "\\frac{" || symbol == "log_{"
    }

    private func shouldBlockTemplateAfter(_ symbol: String) -> Bool {
        symbol == "." || symbol == degreeSymbol || signs.contains(symbol)
    }

    private static func escapeTextValue(_ value: String) -> String {
        if value == " " {
            return "\\ "
        }

        return value
            .replacingOccurrences(of: "\\", with: "\\textbackslash{}")
            .replacingOccurrences(of: "{", with: "\\{")
            .replacingOccurrences(of: "}", with: "\\}")
    }

    private func renderableLatex<S: Sequence>(from tokens: S) -> String where S.Element == String {
        var output = ""

        for token in tokens {
            if shouldAllowLineBreak(before: token, after: output) {
                output += "\\allowbreak "
            }
            output += token
        }

        return output
    }

    private func shouldAllowLineBreak(before token: String, after output: String) -> Bool {
        guard !output.isEmpty else { return false }

        if token.hasPrefix("\\text{") || output.hasSuffix("\\text{") {
            return false
        }

        if trigFunctions.contains(token)
            || token == "\\sqrt("
            || token == "\\sqrt{"
            || token == "\\sqrt["
            || token == "\\frac{"
            || token == "log_{"
            || token == "(" {
            return true
        }

        return token == "+"
            || token == "-"
            || token == "*"
            || token == "\\times "
            || token == "="
            || token == "<"
            || token == ">"
            || token == "\\leq "
            || token == "\\geq "
            || token == "\\cup"
    }
}
