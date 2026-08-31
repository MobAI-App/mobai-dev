//
//  _Translation_SwiftUI.swift
//  The SDK's cross-import overlay for Translation + SwiftUI, as an empty
//  module: app files gate their translation UI behind
//  `#if canImport(_Translation_SwiftUI)`, and without a module by this
//  name the WHOLE file compiles to nothing, taking its other extensions
//  (addTranslateView) away from every caller.
//
