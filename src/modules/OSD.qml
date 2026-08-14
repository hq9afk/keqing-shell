pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.config
import qs.service

Scope {
    Loader {
        active: SettingsService.adapter.osd.active.indexOf("Sink") !== -1

        sourceComponent: Component {
            Scope {
                Variants {
                    model: Quickshell.screens

                    delegate: Component {
                        Scope {
                            id: screenScope

                            required property var modelData

                            PanelWindow {
                                id: osdWindow

                                property bool ready: false

                                function show() {
                                    if (!ready)
                                        return;
                                    osdContent.show();
                                }

                                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                                WlrLayershell.layer: WlrLayer.Overlay
                                WlrLayershell.namespace: "keqing-osd"
                                anchors.bottom: true
                                color: "transparent"
                                implicitHeight: OsdConfig.panelHeight
                                implicitWidth: OsdConfig.panelWidth
                                margins.bottom: OsdConfig.marginBottom
                                screen: screenScope.modelData
                                visible: DisplayService.showOsd(screenScope.modelData)

                                mask: Region {}

                                Connections {
                                    function onSinkMutedChanged() {
                                        osdWindow.show();
                                    }
                                    function onSinkVolumeChanged() {
                                        osdWindow.show();
                                    }

                                    target: VolumeService
                                }
                                Timer {
                                    interval: OsdConfig.readyDelay
                                    running: true

                                    onTriggered: osdWindow.ready = true
                                }

                                // Content
                                Item {
                                    id: osdContent

                                    function hide() {
                                        opacity = OsdConfig.opacityHidden;
                                        scale = OsdConfig.scaleHidden;
                                    }
                                    function show() {
                                        hideTimer.restart();
                                        opacity = OsdConfig.opacityVisible;
                                        scale = OsdConfig.scaleVisible;
                                    }

                                    anchors.fill: parent
                                    opacity: OsdConfig.opacityHidden
                                    scale: OsdConfig.scaleHidden
                                    visible: opacity > 0

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: GlobalConfig.animationNormal
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: GlobalConfig.animationNormal
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Timer {
                                        id: hideTimer

                                        interval: OsdConfig.hideDelay

                                        onTriggered: osdContent.hide()
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        border.color: ColorConfig.electro
                                        border.width: GlobalConfig.borderWidthThin
                                        color: ColorConfig.overlay
                                        radius: height / 2

                                        // Icon
                                        Text {
                                            id: volIcon

                                            anchors.left: parent.left
                                            anchors.leftMargin: OsdConfig.contentMargin
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: VolumeService.sinkMuted ? "#e05555" : ColorConfig.accent
                                            font.family: IconConfig.fontFamily
                                            font.pixelSize: FontConfig.fontOsdIcon
                                            text: {
                                                if (VolumeService.sinkMuted)
                                                    return IconConfig.volumeMute;
                                                if (VolumeService.sinkVolume === 0)
                                                    return IconConfig.volumeEmpty;
                                                if (VolumeService.sinkVolume < 0.5)
                                                    return IconConfig.volumeLow;
                                                return IconConfig.volumeHigh;
                                            }

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: GlobalConfig.animationFast
                                                }
                                            }
                                        }

                                        // Percentage label
                                        Text {
                                            id: pctLabel

                                            anchors.right: parent.right
                                            anchors.rightMargin: OsdConfig.contentMargin
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: ColorConfig.text
                                            font.family: FontConfig.fontFamily
                                            font.pixelSize: FontConfig.fontOsdLabel
                                            horizontalAlignment: Text.AlignRight
                                            text: VolumeService.sinkMuted ? "muted" : Math.round(VolumeService.sinkVolume * 100) + "%"
                                            width: OsdConfig.labelWidth
                                        }

                                        // Progress bar
                                        Rectangle {
                                            anchors.left: volIcon.right
                                            anchors.leftMargin: OsdConfig.barMargin
                                            anchors.right: pctLabel.left
                                            anchors.rightMargin: OsdConfig.barMargin
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: ColorConfig.textAlpha12
                                            height: OsdConfig.barHeight
                                            radius: OsdConfig.barRadius

                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                color: VolumeService.sinkMuted ? "#e05555" : ColorConfig.accent
                                                radius: parent.radius
                                                width: parent.width * Math.min(1.0, VolumeService.sinkMuted ? 0 : VolumeService.sinkVolume)

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: GlobalConfig.animationFast
                                                    }
                                                }
                                                Behavior on width {
                                                    NumberAnimation {
                                                        duration: GlobalConfig.animationFast
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Loader {
        active: SettingsService.adapter.osd.active.indexOf("Source") !== -1

        sourceComponent: Component {
            Scope {
                Variants {
                    model: Quickshell.screens

                    delegate: Component {
                        Scope {
                            id: sourceScreenScope

                            required property var modelData

                            PanelWindow {
                                id: sourceOsdWindow

                                property bool ready: false

                                function show() {
                                    if (!ready)
                                        return;
                                    sourceOsdContent.show();
                                }

                                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                                WlrLayershell.layer: WlrLayer.Overlay
                                WlrLayershell.namespace: "keqing-osd"
                                anchors.bottom: true
                                color: "transparent"
                                implicitHeight: OsdConfig.panelHeight
                                implicitWidth: OsdConfig.panelWidth
                                margins.bottom: OsdConfig.marginBottom
                                screen: sourceScreenScope.modelData
                                visible: DisplayService.showOsd(sourceScreenScope.modelData)

                                mask: Region {}

                                Connections {
                                    function onSourceMutedChanged() {
                                        sourceOsdWindow.show();
                                    }
                                    function onSourceVolumeChanged() {
                                        sourceOsdWindow.show();
                                    }

                                    target: VolumeService
                                }
                                Timer {
                                    interval: OsdConfig.readyDelay
                                    running: true

                                    onTriggered: sourceOsdWindow.ready = true
                                }

                                // Content
                                Item {
                                    id: sourceOsdContent

                                    function hide() {
                                        opacity = OsdConfig.opacityHidden;
                                        scale = OsdConfig.scaleHidden;
                                    }
                                    function show() {
                                        sourceHideTimer.restart();
                                        opacity = OsdConfig.opacityVisible;
                                        scale = OsdConfig.scaleVisible;
                                    }

                                    anchors.fill: parent
                                    opacity: OsdConfig.opacityHidden
                                    scale: OsdConfig.scaleHidden
                                    visible: opacity > 0

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: GlobalConfig.animationNormal
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: GlobalConfig.animationNormal
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Timer {
                                        id: sourceHideTimer

                                        interval: OsdConfig.hideDelay

                                        onTriggered: sourceOsdContent.hide()
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        border.color: ColorConfig.electro
                                        border.width: GlobalConfig.borderWidthThin
                                        color: ColorConfig.overlay
                                        radius: height / 2

                                        // Icon
                                        Text {
                                            id: micIcon

                                            anchors.left: parent.left
                                            anchors.leftMargin: OsdConfig.contentMargin
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: VolumeService.sourceMuted ? "#e05555" : ColorConfig.accent
                                            font.family: IconConfig.fontFamily
                                            font.pixelSize: FontConfig.fontOsdIcon
                                            text: VolumeService.sourceMuted ? IconConfig.micOff : IconConfig.micOn

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: GlobalConfig.animationFast
                                                }
                                            }
                                        }

                                        // Percentage label
                                        Text {
                                            id: sourcePctLabel

                                            anchors.right: parent.right
                                            anchors.rightMargin: OsdConfig.contentMargin
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: ColorConfig.text
                                            font.family: FontConfig.fontFamily
                                            font.pixelSize: FontConfig.fontOsdLabel
                                            horizontalAlignment: Text.AlignRight
                                            text: VolumeService.sourceMuted ? "muted" : Math.round(VolumeService.sourceVolume * 100) + "%"
                                            width: OsdConfig.labelWidth
                                        }

                                        // Progress bar
                                        Rectangle {
                                            anchors.left: micIcon.right
                                            anchors.leftMargin: OsdConfig.barMargin
                                            anchors.right: sourcePctLabel.left
                                            anchors.rightMargin: OsdConfig.barMargin
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: ColorConfig.textAlpha12
                                            height: OsdConfig.barHeight
                                            radius: OsdConfig.barRadius

                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                color: VolumeService.sourceMuted ? "#e05555" : ColorConfig.accent
                                                radius: parent.radius
                                                width: parent.width * Math.min(1.0, VolumeService.sourceMuted ? 0 : VolumeService.sourceVolume)

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: GlobalConfig.animationFast
                                                    }
                                                }
                                                Behavior on width {
                                                    NumberAnimation {
                                                        duration: GlobalConfig.animationFast
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
