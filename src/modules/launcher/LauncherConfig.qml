pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

import qs.config

QtObject {

    // Bullets
    property int bulletsIconSize: 25
    property int bulletsSpacing: 10

    // App
    readonly property string editor: "code"

    // Entry / list
    property int entryBorderWidth: 2
    property int entryContentMargin: 10
    property int entryContentSpacing: 10
    property int entryHeight: 40
    property int entryIconGlyphPointSize: 14
    property int entryIconSize: 23
    property int entryRadius: 5
    property int entrySubtitleOffsetY: 21
    property real entrySubtitleOpacity: 0.65
    property int entrySubtitlePointSize: 8
    property int entryTitleOffsetY: 6
    property int entryTitlePointSize: 12

    // Highlight
    property int highlightBorderWidth: 2
    property int highlightMoveMs: 140
    property real highlightOpacity: 0.5
    property int highlightRadius: 5
    property int highlightResizeMs: 90
    property int innerMargins: 10
    property int innerSpacing: 10
    property int listSpacing: 10
    property int maxVisibleEntries: 6

    // Menu
    property int menuAnimMs: 200
    property real menuBgAlpha: 0.8
    property int menuBorderWidth: 4
    property real menuBrowseWidthRatio: 0.5
    property int menuEntranceMs: 160
    property real menuEntranceOpacityEnd: 1.0
    property real menuEntranceOpacityStart: 0
    property real menuEntranceScaleEnd: 1.0
    property real menuEntranceScaleStart: 0.97
    property int menuRadius: 10
    property int menuWidth: 700

    // Modes
    readonly property string modeDrun: "drun"
    readonly property string modeDuckDuckGo: "duckduckgo"
    readonly property string modeGoogle: "google"
    readonly property var modeIcons: ({
            "drun": IconConfig.apps,
            "run": IconConfig.terminal,
            "google": IconConfig.brandGoogle,
            "duckduckgo": "D",
            "youtube": IconConfig.brandYoutube,
            "url": IconConfig.link
        })
    readonly property string modeRun: "run"
    readonly property string modeUrl: "url"
    readonly property string modeYouTube: "youtube"
    property int resultsSpacing: 10
    property var searchPrefixes: ({
            ">": "run",
            "gg": "google",
            "ddg": "duckduckgo",
            "yt": "youtube",
            "url": "url"
        })

    // Searchbar
    property int searchbarBorderWidth: 2
    property int searchbarFontPx: 18
    property int searchbarPadding: 10
    property int searchbarRadius: 5
    property int searchbarSpacing: 10
    property int snapAnimMs: 90
}
