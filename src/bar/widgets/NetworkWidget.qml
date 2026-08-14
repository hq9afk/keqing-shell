pragma ComponentBehavior: Bound

import QtQuick

import qs.service
import qs.bar.components
import qs.config

WidgetCapsule {
    id: root

    readonly property bool connected: ethernet || ssid !== ""
    readonly property bool ethernet: NetworkService.ethernetConnected
    readonly property bool isPortal: NetworkService.connectivity === "portal"
    readonly property string networkLabel: ethernet ? "Ethernet" : ssid
    readonly property string ssid: NetworkService.connectedSsid

    iconGlyph: {
        if (root.isPortal)
            return IconConfig.lock;
        if (root.ethernet)
            return IconConfig.router;
        if (root.ssid !== "") {
            var sig = NetworkService.connectedSignal;
            if (sig > 75)
                return IconConfig.wifi;
            if (sig > 50)
                return IconConfig.wifi2;
            if (sig > 25)
                return IconConfig.wifi1;
            return IconConfig.wifi0;
        }
        if (NetworkService.ethernetAvailable && !NetworkService.wifiAvailable)
            return IconConfig.router;
        return IconConfig.wifiOff;
    }
    labelText: root.isPortal ? "Sign in" : (root.networkLabel !== "" ? root.networkLabel : "Wi-Fi")
    panelName: "networkPanel"
    showLabel: isPanelOpen || (baseShowLabel && (root.networkLabel !== "" || root.isPortal))

    MouseArea {
        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: PanelService.getPanel("networkPanel", root.screen)?.toggle(root)
    }
}
