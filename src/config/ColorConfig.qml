pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

QtObject {
    // Accent
    property color accent: "#9B57F4"
    readonly property color accentAlpha12: Qt.rgba(accent.r, accent.g, accent.b, 0.12)
    readonly property color accentAlpha15: Qt.rgba(accent.r, accent.g, accent.b, 0.15)
    readonly property color accentAlpha18: Qt.rgba(accent.r, accent.g, accent.b, 0.18)
    readonly property color accentAlpha20: Qt.rgba(accent.r, accent.g, accent.b, 0.20)
    readonly property color accentAlpha25: Qt.rgba(accent.r, accent.g, accent.b, 0.25)
    property color accentContainer: "#3C1877"

    // Accent alt
    property color accentAlt: "#DBAA24"
    property color accentAltContainer: "#2A1957"

    // Base
    property color base: "#0A0614"
    readonly property color baseAlpha45: Qt.rgba(base.r, base.g, base.b, 0.45)
    readonly property color overlay: Qt.rgba(base.r, base.g, base.b, 0.92)

    // Lavender
    property color lavender: "#806FBE"
    readonly property color lavenderAlpha20: Qt.rgba(lavender.r, lavender.g, lavender.b, 0.20)
    readonly property color lavenderAlpha35: Qt.rgba(lavender.r, lavender.g, lavender.b, 0.35)
    readonly property color lavenderSubtle: Qt.rgba(lavender.r, lavender.g, lavender.b, 0.15)

    // Surfaces
    property color fieldBg: "#170D30"
    property color surfaceAlt: "#1D113B"

    // Text
    property color text: "#F0ECF9"
    readonly property color textAlpha03: Qt.rgba(text.r, text.g, text.b, 0.03)
    readonly property color textAlpha04: Qt.rgba(text.r, text.g, text.b, 0.04)
    readonly property color textAlpha05: Qt.rgba(text.r, text.g, text.b, 0.05)
    readonly property color textAlpha06: Qt.rgba(text.r, text.g, text.b, 0.06)
    readonly property color textAlpha07: Qt.rgba(text.r, text.g, text.b, 0.07)
    readonly property color textAlpha08: Qt.rgba(text.r, text.g, text.b, 0.08)
    readonly property color textAlpha10: Qt.rgba(text.r, text.g, text.b, 0.10)
    readonly property color textAlpha12: Qt.rgba(text.r, text.g, text.b, 0.12)
    readonly property color textAlpha13: Qt.rgba(text.r, text.g, text.b, 0.13)
    readonly property color textAlpha14: Qt.rgba(text.r, text.g, text.b, 0.14)
    readonly property color textAlpha15: Qt.rgba(text.r, text.g, text.b, 0.15)
    readonly property color textAlpha18: Qt.rgba(text.r, text.g, text.b, 0.18)
    readonly property color textAlpha20: Qt.rgba(text.r, text.g, text.b, 0.20)
    readonly property color textAlpha35: Qt.rgba(text.r, text.g, text.b, 0.35)
    property color textMuted: "#AB9DC8"
    readonly property color textDim: Qt.rgba(textMuted.r, textMuted.g, textMuted.b, 0.6)

    // Fixed; not palette-derived
    readonly property color electro: "#9D3EF2"

    // Accent
    Behavior on accent {
        ColorAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }
    }
    Behavior on accentContainer {
        ColorAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }
    }

    // Accent alt
    Behavior on accentAlt {
        ColorAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }
    }
    Behavior on accentAltContainer {
        ColorAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }
    }

    // Base
    Behavior on base {
        ColorAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }
    }

    // Lavender
    Behavior on lavender {
        ColorAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }
    }

    // Surfaces
    Behavior on fieldBg {
        ColorAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }
    }
    Behavior on surfaceAlt {
        ColorAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }
    }

    // Text
    Behavior on text {
        ColorAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }
    }
    Behavior on textMuted {
        ColorAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }
    }
}
