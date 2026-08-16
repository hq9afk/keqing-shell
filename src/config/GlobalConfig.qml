pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

QtObject {
    id: root

    // System
    readonly property string user: Quickshell.env("USER")

    // Time Format
    readonly property string timeFormat: "ddd yyyy-MM-dd hh:mm:ss"

    // Helper Function
    function asset(path) {
        return Qt.resolvedUrl("../assets/" + path);
    }

    // Animation
    readonly property int animationFast: 150
    readonly property int animationNormal: 220

    // Sizing
    readonly property int borderWidthThick: 4
    readonly property int borderWidthThin: 2
    readonly property int radiusMd: 10
    readonly property int radiusSm: 5

    // Assets
    readonly property url defaultWallpaper: asset("default_wp.svg")
    readonly property url inputEcho: asset("electro.png")
    readonly property url starwardLogo: asset("gifs/starwardlogo.gif")
    readonly property url userPfp: asset("gifs/userpfp.gif")
    readonly property url pamConfigDir: asset("")
    readonly property string pamConfigFile: "pam.conf"
    function constellation(index) {
        return asset("constellation/C" + index + ".png");
    }
}
