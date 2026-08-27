pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

QtObject {
    id: root

    // Font
    readonly property string fontFamily: tablerIconsLoader.status === FontLoader.Ready ? tablerIconsLoader.name : ""
    readonly property var tablerIconsLoader: FontLoader {
        source: Qt.resolvedUrl("../assets/fonts/tabler-icons.ttf")
    }

    // Settings
    readonly property string adjustments: "\uea03"
    readonly property string bell: "\uea35"
    readonly property string deviceDesktop: "\uea89"
    readonly property string edit: "\uea98"
    readonly property string home: "\ueac1"
    readonly property string layoutBottombar: "\uead3"
    readonly property string layoutNavbar: "\uead7"
    readonly property string moonStars: "\uece7"
    readonly property string palette: "\ueb01"
    readonly property string wallpaper: "\uef56"

    // Status
    readonly property string alertTriangle: "\uea06"

    // Launcher
    readonly property string apps: "\uebb6"
    readonly property string terminal: "\uebdc"

    // Navigation
    readonly property string arrowLeft: "\uea19"
    readonly property string arrowNarrowDown: "\uea1a"
    readonly property string arrowNarrowUp: "\uea1d"
    readonly property string arrowRight: "\uea1f"

    // Battery
    readonly property string battery1: "\uea2f"
    readonly property string battery2: "\uea30"
    readonly property string battery3: "\uea31"
    readonly property string battery4: "\uea32"
    readonly property string batteryCharging: "\uea33"
    readonly property string batteryDisabled: "\ued1c"
    readonly property string pluggedIn: "\uef3b"

    // Bluetooth
    readonly property string bluetoothConnected: "\uecea"
    readonly property string bluetoothDevice: "\uea37"
    readonly property string bluetoothOff: "\ueceb"
    readonly property string bluetoothOn: "\uea37"

    // Brands
    readonly property string brandGoogle: "\uec1f"
    readonly property string brandYoutube: "\uec90"

    // Actions
    readonly property string check: "\uea5e"
    readonly property string chevronDown: "\uea5f"
    readonly property string chevronLeft: "\uea60"
    readonly property string chevronRight: "\uea61"
    readonly property string chevronUp: "\uea62"
    readonly property string close: "\ueb55"
    readonly property string code: "\uea77"
    readonly property string link: "\ueade"
    readonly property string refresh: "\ueb13"

    // System
    readonly property string cpu: "\uef8e"
    readonly property string dashboard: "\uec42"
    readonly property string folder: "\ueaad"
    readonly property string folderOpen: "\ufaf7"
    readonly property string gpu: "\uef8d"
    readonly property string settings: "\ueb20"

    // Lock
    readonly property string lock: "\ueae2"
    readonly property string lockOpen: "\ueae1"

    // Microphone
    readonly property string micOff: "\ued16"
    readonly property string micOn: "\ueaf0"

    // Media
    readonly property string musicNote: "\ueafc"
    readonly property string playerNext: "\ued4b"
    readonly property string playerPause: "\ued45"
    readonly property string playerPlay: "\ued46"
    readonly property string playerPrev: "\ued4c"

    // Overview
    readonly property string overview: "\ueef6"

    // Power
    readonly property string power: "\ueb0d"

    // Volume
    readonly property string volumeEmpty: "\ud800\udd9d"
    readonly property string volumeHigh: "\ueb51"
    readonly property string volumeLow: "\ueb4f"
    readonly property string volumeMute: "\uf1c3"

    // Network
    readonly property string router: "\ueb18"
    readonly property string wifi: "\ueb52"
    readonly property string wifi0: "\ueba3"
    readonly property string wifi1: "\ueba4"
    readonly property string wifi2: "\ueba5"
    readonly property string wifiOff: "\uecfa"
}
