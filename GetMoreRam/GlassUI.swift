//
//  GlassUI.swift
//  GetMoreRam
//
//  Shared native Liquid Glass styling for iOS 26+, with a material fallback
//  for older deployment targets.
//

import SwiftUI

/// Atmospheric graphite backdrop inspired by the app icon. It stays behind
/// content so Apple's glass surfaces can refract the background naturally.
struct AppGlassBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black

                LinearGradient(
                    // Near-black graphite gradient keeps the native glass
                    // readable without washing the screen into grey.
                    colors: [
                        Color(red: 0.035, green: 0.038, blue: 0.045),
                        Color(red: 0.012, green: 0.014, blue: 0.018),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color(red: 0.72, green: 0.78, blue: 0.86).opacity(0.045))
                    .frame(width: proxy.size.width * 0.78)
                    .blur(radius: 100)
                    .offset(x: proxy.size.width * 0.42, y: -proxy.size.height * 0.34)

                Circle()
                    .fill(Color.white.opacity(0.022))
                    .frame(width: proxy.size.width * 0.66)
                    .blur(radius: 90)
                    .offset(x: -proxy.size.width * 0.50, y: proxy.size.height * 0.10)

                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.78)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct GlassSectionHeading: View {
    let title: String
    var subtitle: String? = nil
    var symbol: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 42, height: 42)
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.075))
                    }
                    .overlay {
                        Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

struct GlassIconBadge: View {
    let symbol: String
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.40, weight: .semibold))
            .foregroundStyle(.white.opacity(0.95))
            .frame(width: size, height: size)
            .background {
                Circle().fill(Color.white.opacity(0.075))
            }
            .overlay {
                Circle().strokeBorder(Color.white.opacity(0.16), lineWidth: 0.8)
            }
    }
}

private struct LiquidGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var borderOpacity: Double

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background {
                if #available(iOS 26.0, *) {
                    shape.fill(Color.clear).glassEffect(.regular, in: shape)
                } else {
                    shape.fill(.ultraThinMaterial)
                }
            }
            .overlay {
                shape.strokeBorder(Color.white.opacity(borderOpacity), lineWidth: 0.8)
            }
            .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 9)
    }
}

extension View {
    /// Uses real system Liquid Glass on iOS 26 and a subtle material surface on
    /// earlier systems. The shape follows the card's bounds.
    func liquidGlassCard(cornerRadius: CGFloat = 26, borderOpacity: Double = 0.14) -> some View {
        modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, borderOpacity: borderOpacity))
    }
}

struct LiquidGlassButtonStyle: ButtonStyle {
    var prominent = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                if #available(iOS 26.0, *) {
                    if prominent {
                        Capsule()
                            .fill(Color.clear)
                            .glassEffect(.regular.tint(Color.white.opacity(0.10)).interactive(), in: Capsule())
                    } else {
                        Capsule()
                            .fill(Color.clear)
                            .glassEffect(.regular.interactive(), in: Capsule())
                    }
                } else {
                    Capsule().fill(.ultraThinMaterial)
                }
            }
            .overlay {
                Capsule().strokeBorder(
                    Color.white.opacity(configuration.isPressed ? 0.30 : (prominent ? 0.22 : 0.13)),
                    lineWidth: 0.8
                )
            }
            .opacity(isEnabled ? 1 : 0.48)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct GlassTextFieldSurface<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlassCard(cornerRadius: 17, borderOpacity: 0.11)
    }
}

struct GlassStatusPill: View {
    let title: String
    var symbol: String = "checkmark.circle.fill"

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background {
                Capsule().fill(Color.white.opacity(0.075))
            }
            .overlay {
                Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.7)
            }
    }
}
