pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth

import qs.components
import qs.service
import qs.bar
import qs.bar.layout.components
import qs.bar.service
import qs.config

WidgetPanel {
    id: panelRoot

    function startScan() {
        if (BluetoothService.available && BluetoothService.enabled) {
            BluetoothService.setScanning(true);
            scanTimeout.restart();
        }
    }

    clip: true
    implicitHeight: Math.min(480, BarConfig.panelPadding + header.height + BarConfig.panelHeaderDividerGap + topDiv.height + BarConfig.panelContentGap + content.contentHeight + BarConfig.panelPadding)
    implicitWidth: BarConfig.panelWidthMedium

    Component.onCompleted: startScan()
    Component.onDestruction: BluetoothService.setScanning(false)

    Connections {
        function onEnabledChanged() {
            panelRoot.startScan();
        }

        target: BluetoothService
    }
    Timer {
        id: scanTimeout

        interval: BarConfig.bluetoothScanTimeoutMs

        onTriggered: BluetoothService.setScanning(false)
    }
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
            text: "Bluetooth"
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: BarConfig.panelRowGap

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                color: ColorConfig.accent
                height: BarConfig.panelStatusDotSize
                radius: BarConfig.panelStatusDotRadius
                visible: BluetoothService.available && BluetoothService.scanning
                width: BarConfig.panelStatusDotSize
            }
            Toggle {
                active: BluetoothService.enabled
                anchors.verticalCenter: parent.verticalCenter
                visible: BluetoothService.available

                onToggled: BluetoothService.setEnabled(!BluetoothService.enabled)
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

            Item {
                height: visible ? BarConfig.bluetoothEmptyStateHeight : 0
                visible: !BluetoothService.available
                width: parent.width

                Column {
                    anchors.centerIn: parent
                    spacing: BarConfig.panelContentGap

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: ColorConfig.textDim
                        font.family: FontConfig.fontFamily
                        font.pixelSize: FontConfig.fontBody
                        text: "No adapter found"
                    }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: retryMa.containsMouse ? Qt.lighter(ColorConfig.accent, 1.2) : ColorConfig.accent
                        height: BarConfig.panelActionButtonSize
                        radius: BarConfig.panelActionButtonRadius
                        width: retryLabel.implicitWidth + BarConfig.bluetoothRetryButtonPaddingH

                        Text {
                            id: retryLabel

                            anchors.centerIn: parent
                            color: "white"
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody - 1
                            text: "Retry"
                        }
                        MouseArea {
                            id: retryMa

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: Quickshell.execDetached(["keqing-shell", "restart"])
                        }
                    }
                }
            }
            Item {
                height: visible ? BarConfig.bluetoothOffStateHeight : 0
                visible: BluetoothService.available && !BluetoothService.enabled
                width: parent.width

                Text {
                    anchors.centerIn: parent
                    color: ColorConfig.textDim
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody
                    text: "Bluetooth is off"
                }
            }
            Item {
                height: visible ? BarConfig.bluetoothOffStateHeight : 0
                visible: BluetoothService.enabled && BluetoothService.connectedDevices.length === 0 && BluetoothService.pairedDevices.length === 0 && BluetoothService.nearbyDevices.length === 0
                width: parent.width

                Text {
                    anchors.centerIn: parent
                    color: ColorConfig.textDim
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody
                    text: "No paired devices"
                }
            }
            Item {
                height: visible ? BarConfig.bluetoothSectionGapSmall : 0
                visible: BluetoothService.enabled && BluetoothService.connectedDevices.length > 0
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
                model: BluetoothService.enabled ? BluetoothService.connectedDevices : []

                delegate: DevRow {}
            }
            Item {
                height: visible ? BarConfig.bluetoothSectionGapLarge : 0
                visible: BluetoothService.enabled && BluetoothService.pairedDevices.length > 0
                width: parent.width

                Text {
                    anchors.bottom: parent.bottom
                    color: ColorConfig.textDim
                    font.bold: true
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody - 1
                    text: "Paired"
                }
            }
            Repeater {
                model: BluetoothService.enabled ? BluetoothService.pairedDevices : []

                delegate: DevRow {}
            }
            Item {
                height: visible ? BarConfig.bluetoothSectionGapLarge : 0
                visible: BluetoothService.scanning && BluetoothService.nearbyDevices.length > 0
                width: parent.width

                Text {
                    anchors.bottom: parent.bottom
                    color: ColorConfig.textDim
                    font.bold: true
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody - 1
                    text: "Nearby"
                }
            }
            Repeater {
                model: BluetoothService.scanning ? BluetoothService.nearbyDevices : []

                delegate: DevRow {}
            }
            Item {
                height: BarConfig.panelTrailingSpacerHeight
                width: 1
            }
        }
    }

    component DevRow: Item {
        id: devRow

        property int _prevState: modelData.state
        property bool connectFailed: false
        readonly property bool isBusy: BluetoothService.isBusy(modelData)
        readonly property bool isConnected: modelData.connected
        readonly property bool isPairedOrConnected: {
            try {
                return modelData.paired || modelData.trusted || modelData.connected;
            } catch (e) {
                return false;
            }
        }
        required property var modelData
        readonly property bool needsRepair: BluetoothService.needsRepair(modelData)

        height: BarConfig.panelDeviceRowHeight
        width: parent.width

        onConnectFailedChanged: if (connectFailed)
            failClearTimer.restart()

        Connections {
            function onStateChanged() {
                if (devRow._prevState === BluetoothDevice.Connecting && devRow.modelData.state === BluetoothDevice.Disconnected)
                    devRow.connectFailed = true;
                else if (devRow.modelData.state === BluetoothDevice.Connecting)
                    devRow.connectFailed = false;
                devRow._prevState = devRow.modelData.state;
            }

            target: devRow.modelData
        }
        Timer {
            id: failClearTimer

            interval: BarConfig.bluetoothConnectFailClearMs

            onTriggered: devRow.connectFailed = false
        }
        Rectangle {
            anchors.fill: parent
            color: {
                if (devRow.isConnected)
                    return ColorConfig.accentAlpha25;
                if (devRow.isBusy)
                    return ColorConfig.accentAlpha12;
                return devHover.containsMouse ? ColorConfig.overlay : ColorConfig.overlay;
            }
            radius: BarConfig.panelListRowRadius

            HoverHandler {
                id: devHover
            }
            Text {
                id: devIcon

                anchors.left: parent.left
                anchors.leftMargin: BarConfig.panelRowIconGap
                anchors.verticalCenter: parent.verticalCenter
                color: ColorConfig.text
                font.family: IconConfig.fontFamily
                font.pixelSize: BarConfig.iconSize
                horizontalAlignment: Text.AlignHCenter
                opacity: devRow.isConnected ? 1.0 : BarConfig.bluetoothDeviceDisconnectedOpacity
                text: IconConfig.bluetoothDevice
                width: BarConfig.iconSize
            }
            Column {
                anchors.left: devIcon.right
                anchors.leftMargin: BarConfig.panelRowIconGap
                anchors.right: devActions.left
                anchors.rightMargin: BarConfig.panelRowActionGap
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    color: devRow.isConnected ? ColorConfig.accent : ColorConfig.text
                    elide: Text.ElideRight
                    font.bold: devRow.isConnected
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody
                    text: BluetoothService.deviceName(devRow.modelData)
                    width: parent.width
                }
                Text {
                    color: ColorConfig.accent
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody - 2
                    text: {
                        try {
                            if (devRow.modelData.pairing)
                                return "Pairing…";
                            if (devRow.modelData.state === BluetoothDevice.Connecting)
                                return "Connecting…";
                            if (devRow.modelData.state === BluetoothDevice.Disconnecting)
                                return "Disconnecting…";
                        } catch (e) {}
                        return "";
                    }
                    visible: devRow.isBusy
                }
                Row {
                    spacing: 3
                    visible: !devRow.isBusy && devRow.modelData.batteryAvailable

                    Text {
                        color: ColorConfig.textDim
                        font.family: IconConfig.fontFamily
                        font.pixelSize: FontConfig.fontBody - 2
                        text: {
                            try {
                                var b = devRow.modelData.battery;
                                if (b === undefined)
                                    return "";
                                var pct = Math.round(b * 100);
                                if (pct <= 20)
                                    return IconConfig.battery1;
                                if (pct <= 40)
                                    return IconConfig.battery2;
                                if (pct <= 80)
                                    return IconConfig.battery3;
                                return IconConfig.battery4;
                            } catch (e) {
                                return "";
                            }
                        }
                    }
                    Text {
                        color: ColorConfig.textDim
                        font.family: FontConfig.fontFamily
                        font.pixelSize: FontConfig.fontBody - 2
                        text: {
                            try {
                                var b = devRow.modelData.battery;
                                if (b === undefined)
                                    return "";
                                return Math.round(b * 100) + "%";
                            } catch (e) {
                                return "";
                            }
                        }
                    }
                }
            }
            Row {
                id: devActions

                anchors.right: parent.right
                anchors.rightMargin: BarConfig.panelRowIconGap
                anchors.verticalCenter: parent.verticalCenter
                spacing: BarConfig.panelTightGap

                Rectangle {
                    color: {
                        if (devRow.isConnected)
                            return actionMa.containsMouse ? ColorConfig.textAlpha18 : ColorConfig.textAlpha10;
                        return actionMa.containsMouse ? Qt.lighter(ColorConfig.accent, 1.2) : ColorConfig.accent;
                    }
                    height: BarConfig.panelActionButtonSize
                    radius: BarConfig.panelActionButtonRadius
                    visible: !devRow.isBusy
                    width: actionLabel.implicitWidth + BarConfig.panelDialogButtonPaddingH

                    Text {
                        id: actionLabel

                        anchors.centerIn: parent
                        color: devRow.isConnected ? ColorConfig.text : "white"
                        font.family: FontConfig.fontFamily
                        font.pixelSize: FontConfig.fontBody - 1
                        text: devRow.isConnected ? "Disconnect" : "Connect"
                    }
                    MouseArea {
                        id: actionMa

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: {
                            if (devRow.isConnected) {
                                PanelService.openSubPanelForCurrent("bluetoothSubPanel", {
                                    "device": devRow.modelData,
                                    "mode": "disconnect"
                                });
                            } else {
                                BluetoothService.connectDevice(devRow.modelData);
                            }
                        }
                    }
                }
                Rectangle {
                    color: forgetMa.containsMouse ? Qt.rgba(1, 0.27, 0.27, 0.3) : Qt.rgba(1, 0.27, 0.27, 0.12)
                    height: BarConfig.panelActionButtonSize
                    radius: BarConfig.panelActionButtonRadius
                    visible: devRow.isPairedOrConnected && !devRow.isConnected && !devRow.isBusy
                    width: BarConfig.panelActionButtonSize

                    Text {
                        anchors.centerIn: parent
                        color: "#F44747"
                        font.family: IconConfig.fontFamily
                        font.pixelSize: FontConfig.fontListItemRemove
                        text: IconConfig.close
                    }
                    MouseArea {
                        id: forgetMa

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: PanelService.openSubPanelForCurrent("bluetoothSubPanel", {
                            "device": devRow.modelData,
                            "mode": "forget"
                        })
                    }
                }
            }
        }
    }
}
