//
//  Translation.swift
//  Stand-in for Apple's Translation framework.
//
//  A preview never translates; the presentation modifier keeps the screen
//  unchanged, which is the pre-sheet state a still frame shows anyway.
//

import SwiftUI

extension View {
    nonisolated public func translationPresentation(
        isPresented: Binding<Bool>, text: String
    ) -> some View { self }
}
