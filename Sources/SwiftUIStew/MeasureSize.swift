// Copyright (c) 2021 Patrick Sturm <psturm-swift@e.mail.de>
// See LICENSE file for licensing information.

#if os(iOS) || os(watchOS) || os(tvOS) || os(macOS)
import SwiftUI

/// A key for specifying the preferred size of a component.
@available(iOS 13.0.0, tvOS 13.0.0, *)
public struct SizePreferenceKey: PreferenceKey {
    public static let defaultValue: CGSize = .zero

    public static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let newValue = nextValue()
        value = CGSize(
            width: max(value.width, newValue.width),
            height: max(value.height, newValue.height))
    }
}

/// Stores the size of a SwiftUI view as pereference (see ``SizePreferenceKey``)
@available(iOS 13.0.0, tvOS 13.0.0, macOS 11.0.0, *)
public struct MeasureSizeModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { p in
                    Color.clear.preference(
                        key: SizePreferenceKey.self,
                        value: p.size
                    )
                }
            )
    }
}

/// Writes the view's size as preference with preference key ``SizePreferenceKey``
@available(iOS 13.0.0, tvOS 13.0.0, macOS 11.0.0, *)
extension View {
    public func measureSize() -> some View {
        return self.modifier(MeasureSizeModifier())
    }
}

/// Reads the size for preference key ``SizePreferenceKey`` if changed
@available(iOS 13.0.0, tvOS 13.0.0, macOS 11.0.0, *)
public struct ReadSizeModifier: ViewModifier {
    @Binding public var size: CGSize?
    
    public func body(content: Content) -> some View {
        content
            .onPreferenceChange(SizePreferenceKey.self) { size = $0 }
    }
}

/// Reads the height for preference key ``SizePreferenceKey`` if changed
@available(iOS 13.0.0, tvOS 13.0.0, macOS 11.0.0, *)
public struct ReadHeightModifier: ViewModifier {
    @Binding public var height: CGFloat?
    
    public func body(content: Content) -> some View {
        content
            .onPreferenceChange(SizePreferenceKey.self) { height = $0.height }
    }
}

/// Reads the width for preference key ``SizePreferenceKey`` if changed
@available(iOS 13.0.0, tvOS 13.0.0, macOS 11.0.0, *)
public struct ReadWidthModifier: ViewModifier {
    @Binding public var width: CGFloat?
    
    public func body(content: Content) -> some View {
        content
            .onPreferenceChange(SizePreferenceKey.self) { width = $0.width }
    }
}

@available(iOS 13.0.0, tvOS 13.0.0, macOS 11.0.0, *)
extension View {
    /// Updates the binding if value of ``SizePreferenceKey``did change
    public func read(size: Binding<CGSize?>) -> some View {
        return self.modifier(ReadSizeModifier(size: size))
    }

    /// Updates the binding if value of ``SizePreferenceKey``did change
    public func read(height: Binding<CGFloat?>) -> some View {
        return self.modifier(ReadHeightModifier(height: height))
    }

    /// Updates the binding if value of ``SizePreferenceKey``did change
    public func read(width: Binding<CGFloat?>) -> some View {
        return self.modifier(ReadWidthModifier(width: width))
    }
}
#endif
