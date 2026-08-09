pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.bar.layout.components
import qs.bar.layout.popups.panels
import qs.bar.service

PanelWindow {
    id: root

    readonly property bool _active: PanelService.openedScreenName === myScreenName || PanelService.closingScreenName === myScreenName
    property string myScreenName: ""

    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    visible: _active

    Component.onCompleted: myScreenName = screen ? screen.name : ""

    anchors {
        bottom: true
        left: true
        right: true
        top: true
    }
    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: {
            if (PanelService.openedSubPanel)
                PanelService.openedSubPanel.onEscapePressed();
            else if (PanelService.openedPanel)
                PanelService.openedPanel.onEscapePressed();
        }

        MouseArea {
            anchors.fill: parent
            enabled: root._active

            onClicked: PanelService.closePanel()
        }
        Panel {
            panelId: "volumePanel"

            panelContent: Component {
                VolumePanel {}
            }
        }
        Panel {
            id: networkDrop

            panelId: "networkPanel"

            panelContent: Component {
                NetworkPanel {}
            }
        }
        Panel {
            id: bluetoothDrop

            panelId: "bluetoothPanel"

            panelContent: Component {
                BluetoothPanel {}
            }
        }
        Panel {
            panelId: "batteryPanel"

            panelContent: Component {
                BatteryPanel {}
            }
        }
        Panel {
            panelId: "clockPanel"

            panelContent: Component {
                ClockPanel {}
            }
        }
        Panel {
            panelId: "systemMonitorPanel"

            panelContent: Component {
                SystemMonitorPanel {}
            }
        }
        Panel {
            panelId: "trayPanel"

            panelContent: Component {
                TrayPanel {}
            }
        }
        MouseArea {
            anchors.fill: parent
            enabled: PanelService.openedSubPanel !== null
            visible: PanelService.openedSubPanel !== null

            onClicked: PanelService.closeSubPanel()
        }
        Panel {
            attachTo: networkDrop
            panelId: "networkSubPanel"
            z: 1

            panelContent: Component {
                NetworkSubPanel {}
            }
        }
        Panel {
            attachTo: bluetoothDrop
            panelId: "bluetoothSubPanel"
            z: 1

            panelContent: Component {
                BluetoothSubPanel {}
            }
        }
    }

    component Panel: DropPanel {
        required property string panelId

        objectName: panelId + "-" + (screen?.name ?? "")
        screen: root.screen
    }
}
