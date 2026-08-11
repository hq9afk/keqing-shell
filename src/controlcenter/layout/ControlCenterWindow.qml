pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

import qs.service
import qs.bar
import qs.controlcenter
import qs.controlcenter.cards
import qs.config

PanelWindow {
    id: window

    required property bool isOpen

    signal dismissRequested

    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: window.isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    visible: container.width > 0

    onIsOpenChanged: {
        if (isOpen)
            keyHandler.forceActiveFocus();
    }

    anchors {
        bottom: true
        left: true
        right: true
        top: true
    }
    FocusScope {
        id: keyHandler

        anchors.fill: parent
        focus: window.isOpen

        Keys.onEscapePressed: window.dismissRequested()

        MouseArea {
            acceptedButtons: Qt.LeftButton
            anchors.fill: parent
            enabled: window.isOpen

            onClicked: mouse => {
                const inside = mouse.x >= container.x && mouse.x <= container.x + container.width && mouse.y >= container.y && mouse.y <= container.y + container.height;
                if (!inside)
                    window.dismissRequested();
            }
        }
        Item {
            id: container

            clip: true
            height: Math.min(parent.height - y - BarConfig.barMarginH, content.implicitHeight)
            width: window.isOpen ? ControlCenterConfig.panelWidth : 0
            x: parent.width - width - BarConfig.barMarginH
            y: BarConfig.barMarginTop + BarConfig.barHeight + BarConfig.panelGap

            Behavior on width {
                NumberAnimation {
                    duration: GlobalConfig.animationNormal
                    easing.type: Easing.OutCubic

                    onRunningChanged: {
                        if (!running && !window.isOpen && container.width === 0)
                            window.closed();
                    }
                }
            }

            PwObjectTracker {
                objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
            }
            ScrollView {
                id: content

                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                anchors.fill: parent
                implicitHeight: col.implicitHeight

                Column {
                    id: col

                    spacing: ControlCenterConfig.panelColumnSpacing
                    width: container.width

                    ProfileCard {}
                    Repeater {
                        model: ["battery", "systemStats", "cpuTemp", "gpuTemp", "media", "volume"]

                        delegate: CardLoader {
                            required property var modelData

                            cardId: modelData
                            width: col.width
                        }
                    }
                }
            }
        }
    }
}
