pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

QtObject {
    // Animated wallpaper — decode-load cap, applied once per source at import
    readonly property int animatedMaxFps: 24
    readonly property int animatedMaxHeight: 1440

    // Column / layout
    readonly property int columnSpacing: 10

    // ControlRow
    readonly property int controlRowHeight: 35

    // DirBar
    readonly property int dirBarHeight: 40
    readonly property int dirBtnHeight: 28
    readonly property int dirBtnWidth: 72
    readonly property int dirEdgeMargin: 8
    readonly property int dirInputLeftMargin: 10
    readonly property int dirLabelLeftMargin: 14
    readonly property int dropdownBtnPadding: 20
    readonly property int dropdownBtnSpacing: 6

    // Dropdowns
    readonly property var fillModes: [
        {
            label: "Crop",
            mode: "crop"
        },
        {
            label: "Fit",
            mode: "fit"
        }
    ]
    readonly property int gridBorderWidth: 5
    // Grid — source of truth for panel size; change these to resize the whole panel
    readonly property int imagesPerRow: 7

}
