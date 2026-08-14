pragma ComponentBehavior: Bound

import QtQuick

import qs.service
import qs.bar.components
import qs.config

WidgetCapsule {
    id: root

    readonly property var connectedDevice: BluetoothService.connectedDevices.length > 0 ? BluetoothService.connectedDevices[0] : null
    readonly property string connectedName: connectedDevice ? BluetoothService.deviceName(connectedDevice) : ""
    readonly property bool powered: BluetoothService.enabled

    iconGlyph: {
        if (!root.powered)
            return IconConfig.bluetoothOff;
        if (root.connectedDevice !== null)
            return IconConfig.bluetoothConnected;
        return IconConfig.bluetoothOn;
    }
    labelText: {
        if (!BluetoothService.available)
            return "Unavailable";
        if (!root.powered)
            return "Disconnected";
        if (root.connectedDevice !== null)
            return root.connectedName;
        return "Idle";
    }
    panelName: "bluetoothPanel"
    showLabel: baseShowLabel

    MouseArea {
        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: PanelService.getPanel("bluetoothPanel", root.screen)?.toggle(root)
    }
}
