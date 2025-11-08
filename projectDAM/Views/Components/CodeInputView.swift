//
//  CodeInputView.swift
//  projectDAM
//
//  Created on 11/8/2025.
//

import SwiftUI

struct CodeInputView: View {
    @Binding var code: String
    @FocusState private var isFocused: Bool
    @State private var internalCode: String = ""
    let digitCount: Int = 6
    let onComplete: (() -> Void)?
    
    init(code: Binding<String>, onComplete: (() -> Void)? = nil) {
        self._code = code
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack {
            // Hidden TextField for actual input (supports paste and typing)
            TextField("", text: $internalCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode) // Enables SMS autofill
                .focused($isFocused)
                .opacity(0.01)
                .frame(width: 1, height: 1)
                .onChange(of: internalCode) { newValue in
                    handleCodeChange(newValue)
                }
            
            // Visual display boxes
            HStack(spacing: 12) {
                ForEach(0..<digitCount, id: \.self) { index in
                    DigitBox(
                        digit: digitAt(index),
                        isFilled: index < code.count,
                        isFocused: isFocused && index == code.count
                    )
                    .onTapGesture {
                        isFocused = true
                    }
                }
            }
        }
        .onAppear {
            isFocused = true
            internalCode = code
        }
        .onChange(of: code) { newValue in
            if newValue != internalCode {
                internalCode = newValue
            }
        }
    }
    
    private func digitAt(_ index: Int) -> String {
        guard index < code.count else { return "" }
        let digitIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[digitIndex])
    }
    
    private func handleCodeChange(_ newValue: String) {
        // Filter only digits
        let filtered = newValue.filter { $0.isNumber }
        
        // Limit to digitCount
        let limited = String(filtered.prefix(digitCount))
        
        // Update code binding
        code = limited
        
        // Update internal state if needed
        if internalCode != limited {
            internalCode = limited
        }
        
        // Call completion if code is complete
        if limited.count == digitCount {
            isFocused = false // Dismiss keyboard
            onComplete?()
        }
    }
}

struct DigitBox: View {
    let digit: String
    let isFilled: Bool
    let isFocused: Bool
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
            
            // Border
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 2)
            
            // Digit display or cursor
            if !digit.isEmpty {
                Text(digit)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.primary)
            } else if isFocused {
                // Blinking cursor
                Rectangle()
                    .fill(Color.brandPrimary)
                    .frame(width: 2, height: 30)
                    .opacity(isFocused ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isFocused)
            }
        }
        .frame(width: 50, height: 60)
    }
    
    private var borderColor: Color {
        if isFocused {
            return .brandPrimary
        } else if isFilled {
            return .brandPrimary.opacity(0.5)
        } else {
            return Color(.separator)
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        Text("Enter Verification Code")
            .font(.title2)
            .fontWeight(.bold)
        
        CodeInputView(code: .constant("123")) {
            print("Code complete!")
        }
        
        Text("Code expires in 09:45")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    .padding()
}
