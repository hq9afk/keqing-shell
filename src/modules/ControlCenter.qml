pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

import qs.config
import qs.controlcenter
import qs.elements
import qs.modules
import qs.service

ModuleLoader {
    id: root

    module: "controlcenter"

    sourceComp: Component {
        Scope {
            id: panel

            property alias controller: controller

            signal closeRequested

            // Controller
            Item {
                id: controller

                property bool isOpen: false

                function close() {
                    isOpen = false;
                }
                function open() {
                    isOpen = true;
                }
                function toggle() {
                    if (isOpen)
                        close();
                    else
                        open();
                }
            }

            // Window
            PanelWindow {
                id: window

                property bool isOpen: controller.isOpen

                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.keyboardFocus: window.isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"
                visible: container.width > 0

                onClosed: panel.closeRequested()
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

                    Keys.onEscapePressed: controller.close()

                    MouseArea {
                        acceptedButtons: Qt.LeftButton
                        anchors.fill: parent
                        enabled: window.isOpen

                        onClicked: mouse => {
                            const inside = mouse.x >= container.x && mouse.x <= container.x + container.width && mouse.y >= container.y && mouse.y <= container.y + container.height;
                            if (!inside)
                                controller.close();
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
                                BatteryCard {}
                                SystemStatsCard {}
                                CpuTempCard {}
                                GpuTempCard {}
                                MediaCard {}
                                VolumeCard {}
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        function toggle() {
            root.toggle();
        }

        target: "controlcenter"
    }
}
