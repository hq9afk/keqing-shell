pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.elements
import qs.service
import qs.modules.bar.components
import qs.config

WidgetPanel {
    id: panelRoot

    readonly property var _nets: Object.values(NetworkService.networks)
    readonly property var availableNetworks: _nets.filter(n => !n.connected && !n.existing).sort((a, b) => b.signal - a.signal)
    readonly property var connectedNetworks: _nets.filter(n => n.connected).sort((a, b) => b.signal - a.signal)
    readonly property var savedNetworks: _nets.filter(n => !n.connected && n.existing && n.inRange).sort((a, b) => b.signal - a.signal)
    readonly property int visibleCount: connectedNetworks.length + savedNetworks.length + availableNetworks.length

    function _signalIcon(pct) {
        if (pct > 75)
            return IconConfig.wifi;
        if (pct > 50)
            return IconConfig.wifi2;
        if (pct > 25)
            return IconConfig.wifi1;
        return IconConfig.wifi0;
    }

    clip: true
    implicitHeight: Math.min(520, BarConfig.panelPadding + header.height + BarConfig.panelHeaderDividerGap + topDiv.height + BarConfig.panelContentGap + content.contentHeight + BarConfig.panelPadding)
    implicitWidth: BarConfig.panelWidthMedium

    Component.onCompleted: NetworkService.scan()

    MouseArea {
        anchors.fill: parent
    }
    Item {
        id: header

        anchors.margins: BarConfig.panelPadding
        height: BarConfig.panelHeaderHeight

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: ColorConfig.text
            font.bold: true
            font.family: FontConfig.fontFamily
            font.pixelSize: FontConfig.fontBody + 1
            text: "Network"
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: BarConfig.panelRowGap

            Rectangle {
                color: scanMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
                height: BarConfig.panelActionButtonSize
                radius: BarConfig.panelActionButtonRadius
                visible: NetworkService.wifiAvailable
                width: BarConfig.panelActionButtonSize

                Text {
                    anchors.centerIn: parent
                    color: NetworkService.scanning ? ColorConfig.accent : ColorConfig.text
                    font.family: IconConfig.fontFamily
                    font.pixelSize: FontConfig.fontPanelActionIcon
                    text: IconConfig.refresh
                }
                MouseArea {
                    id: scanMa

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: NetworkService.scan()
                }
            }
            Toggle {
                active: NetworkService.wifiEnabled
                anchors.verticalCenter: parent.verticalCenter
                visible: NetworkService.wifiAvailable

                onToggled: NetworkService.setWifiEnabled(!NetworkService.wifiEnabled)
            }
            Rectangle {
                color: closeMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
                height: BarConfig.panelActionButtonSize
                radius: BarConfig.panelActionButtonRadius
                width: BarConfig.panelActionButtonSize

                Text {
                    anchors.centerIn: parent
                    color: ColorConfig.text
                    font.family: IconConfig.fontFamily
                    font.pixelSize: FontConfig.fontPanelActionIcon
                    text: IconConfig.close
                }
                MouseArea {
                    id: closeMa

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: PanelService.closePanel()
                }
            }
        }
    }
    Divider {
        id: topDiv

        anchors.topMargin: BarConfig.panelHeaderDividerGap

        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
        }
    }
    Flickable {
        id: content

        anchors.margins: BarConfig.panelPadding
        anchors.topMargin: BarConfig.panelContentGap
        clip: true
        contentHeight: col.implicitHeight

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            top: topDiv.bottom
        }
        Column {
            id: col

            spacing: BarConfig.panelListSpacing
            width: content.width

            Rectangle {
                clip: true
                color: Qt.rgba(1, 0.27, 0.27, 0.15)
                height: visible ? errTxt.implicitHeight + BarConfig.networkErrorBannerPaddingV : 0
                radius: BarConfig.panelListRowRadius
                visible: NetworkService.lastError !== ""
                width: parent.width

                Row {
                    anchors.margins: BarConfig.panelRowIconGap
                    spacing: BarConfig.panelRowGap

                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#F44747"
                        font.family: IconConfig.fontFamily
                        font.pixelSize: FontConfig.fontBody
                        text: IconConfig.alertTriangle + " "
                    }
                    Text {
                        id: errTxt

                        anchors.verticalCenter: parent.verticalCenter
                        color: "#F44747"
                        font.family: FontConfig.fontFamily
                        font.pixelSize: FontConfig.fontBody
                        text: NetworkService.lastError
                        width: col.width - BarConfig.networkErrorTextWidthOffset
                        wrapMode: Text.WordWrap
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        color: "transparent"
                        height: BarConfig.networkErrorCloseSize
                        radius: BarConfig.networkErrorCloseRadius
                        width: BarConfig.networkErrorCloseSize

                        Text {
                            anchors.centerIn: parent
                            color: "#F44747"
                            font.family: IconConfig.fontFamily
                            font.pixelSize: FontConfig.fontNetworkClose
                            text: IconConfig.close
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: NetworkService.lastError = ""
                        }
                    }
                }
            }
            Rectangle {
                clip: true
                color: ColorConfig.accentAlpha18
                height: visible ? BarConfig.networkEthernetBannerHeight : 0
                radius: BarConfig.panelListRowRadius
                visible: NetworkService.ethernetConnected
                width: parent.width

                Text {
                    anchors.centerIn: parent
                    color: ColorConfig.text
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody
                    text: "Ethernet"
                }
            }
            Item {
                height: visible ? BarConfig.networkUnavailableStateHeight : 0
                visible: !NetworkService.wifiAvailable
                width: parent.width

                Text {
                    anchors.centerIn: parent
                    color: ColorConfig.textDim
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody
                    text: "No Wi-Fi adapter found"
                }
            }
            Item {
                height: visible ? BarConfig.networkUnavailableStateHeight : 0
                visible: NetworkService.wifiAvailable && !NetworkService.wifiEnabled
                width: parent.width

                Text {
                    anchors.centerIn: parent
                    color: ColorConfig.textDim
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody
                    text: "WiFi is disabled"
                }
            }
            Item {
                height: visible ? BarConfig.networkScanningStateHeight : 0
                visible: NetworkService.wifiAvailable && NetworkService.wifiEnabled && panelRoot.visibleCount === 0
                width: parent.width

                Timer {
                    id: dotTimer

                    property int step: 0

                    interval: BarConfig.networkScanDotIntervalMs
                    repeat: true
                    running: parent.visible

                    onTriggered: step = (step + 1) % 4
                }
                Text {
                    anchors.centerIn: parent
                    color: ColorConfig.textDim
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody
                    text: "Scanning" + ".".repeat(dotTimer.step)
                }
            }
            Item {
                height: visible ? BarConfig.networkSectionGapSmall : 0
                visible: panelRoot.connectedNetworks.length > 0 && NetworkService.wifiEnabled
                width: parent.width

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: ColorConfig.textDim
                    font.bold: true
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody - 1
                    text: "Connected"
                }
            }
            Repeater {
                model: panelRoot.connectedNetworks

                delegate: NetRow {}
            }
            Item {
                height: visible ? BarConfig.networkSectionGapLarge : 0
                visible: panelRoot.savedNetworks.length > 0 && NetworkService.wifiEnabled
                width: parent.width

                Text {
                    anchors.bottom: parent.bottom
                    color: ColorConfig.textDim
                    font.bold: true
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody - 1
                    text: "Known"
                }
            }
            Repeater {
                model: panelRoot.savedNetworks

                delegate: NetRow {}
            }
            Item {
                height: visible ? BarConfig.networkSectionGapLarge : 0
                visible: panelRoot.availableNetworks.length > 0 && NetworkService.wifiEnabled
                width: parent.width

                Text {
                    anchors.bottom: parent.bottom
                    color: ColorConfig.textDim
                    font.bold: true
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody - 1
                    text: "Available"
                }
            }
            Repeater {
                model: panelRoot.availableNetworks

                delegate: NetRow {}
            }
            Item {
                height: BarConfig.panelTrailingSpacerHeight
                width: 1
            }
        }
    }

    component NetRow: Item {
        id: netRow

        readonly property bool isBusy: NetworkService.connectingTo === modelData.ssid
        readonly property bool isCaptive: modelData.connected && NetworkService.connectivity === "portal"
        readonly property bool isConnected: modelData.connected
        readonly property bool isSecured: modelData.security && modelData.security !== "--" && modelData.security.trim() !== ""
        required property var modelData

        height: BarConfig.networkRowHeight
        width: parent.width

        Rectangle {
            color: {
                if (netRow.isCaptive)
                    return Qt.rgba(1, 0.76, 0.03, 0.15);
                if (netRow.isConnected)
                    return ColorConfig.accentAlpha25;
                if (netRow.isBusy)
                    return ColorConfig.accentAlpha12;
                return rowHover.containsMouse ? ColorConfig.overlay : ColorConfig.overlay;
            }
            height: BarConfig.panelDeviceRowHeight
            radius: BarConfig.panelListRowRadius
            width: parent.width

            HoverHandler {
                id: rowHover
            }
            Text {
                anchors.left: parent.left
                anchors.leftMargin: BarConfig.panelRowIconGap
                anchors.verticalCenter: parent.verticalCenter
                color: netRow.isCaptive ? "#FFC107" : netRow.isConnected ? ColorConfig.accent : ColorConfig.textDim
                font.family: IconConfig.fontFamily
                font.pixelSize: BarConfig.iconSize
                text: panelRoot._signalIcon(netRow.modelData.signal)
            }
            Column {
                anchors.left: parent.left
                anchors.leftMargin: 38
                anchors.right: actions.left
                anchors.rightMargin: BarConfig.panelRowActionGap
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                MarqueeText {
                    color: netRow.isCaptive ? "#FFC107" : netRow.isConnected ? ColorConfig.accent : ColorConfig.text
                    fontBold: netRow.isConnected
                    fontFamily: FontConfig.fontFamily
                    fontSize: FontConfig.fontBody
                    text: netRow.modelData.ssid
                    width: parent.width
                }
                Text {
                    color: netRow.isCaptive ? "#FFC107" : ColorConfig.textDim
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody - 2
                    text: netRow.isCaptive ? "Sign in required" : (netRow.isSecured ? netRow.modelData.security.trim() : "Open")
                }
            }
            Row {
                id: actions

                anchors.right: parent.right
                anchors.rightMargin: BarConfig.panelRowIconGap
                anchors.verticalCenter: parent.verticalCenter
                spacing: BarConfig.panelTightGap

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: ColorConfig.accent
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody - 1
                    text: "Connecting…"
                    visible: netRow.isBusy
                }
                Rectangle {
                    color: {
                        if (netRow.isConnected)
                            return netActionMa.containsMouse ? ColorConfig.textAlpha18 : ColorConfig.textAlpha10;
                        return netActionMa.containsMouse ? Qt.lighter(ColorConfig.accent, 1.2) : ColorConfig.accent;
                    }
                    height: BarConfig.panelActionButtonSize
                    radius: BarConfig.panelActionButtonRadius
                    visible: !netRow.isBusy
                    width: netActionLabel.implicitWidth + BarConfig.panelDialogButtonPaddingH

                    Text {
                        id: netActionLabel

                        anchors.centerIn: parent
                        color: netRow.isConnected ? ColorConfig.text : "white"
                        font.family: FontConfig.fontFamily
                        font.pixelSize: FontConfig.fontBody - 1
                        text: netRow.isConnected ? "Disconnect" : "Connect"
                    }
                    MouseArea {
                        id: netActionMa

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: {
                            if (netRow.isConnected) {
                                PanelService.openSubPanelForCurrent("networkSubPanel", {
                                    "ssid": netRow.modelData.ssid,
                                    "mode": "disconnect"
                                });
                            } else if (netRow.modelData.existing || !netRow.isSecured) {
                                NetworkService.connect(netRow.modelData.ssid, "");
                            } else {
                                PanelService.openSubPanelForCurrent("networkSubPanel", {
                                    "ssid": netRow.modelData.ssid,
                                    "mode": "password"
                                });
                            }
                        }
                    }
                }
                Rectangle {
                    color: fMa.containsMouse ? Qt.rgba(1, 0.27, 0.27, 0.3) : Qt.rgba(1, 0.27, 0.27, 0.12)
                    height: BarConfig.panelActionButtonSize
                    radius: BarConfig.panelActionButtonRadius
                    visible: netRow.modelData.existing && !netRow.isConnected && !netRow.isBusy
                    width: BarConfig.panelActionButtonSize

                    Text {
                        anchors.centerIn: parent
                        color: "#F44747"
                        font.family: IconConfig.fontFamily
                        font.pixelSize: FontConfig.fontListItemRemove
                        text: IconConfig.close
                    }
                    MouseArea {
                        id: fMa

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: PanelService.openSubPanelForCurrent("networkSubPanel", {
                            "ssid": netRow.modelData.ssid,
                            "mode": "forget"
                        })
                    }
                }
            }
        }
    }
}
