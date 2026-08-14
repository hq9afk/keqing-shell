pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.service
import qs.bar.components
import qs.config

WidgetCapsule {
    id: root

    property bool peekActive: false
    property bool peekReady: false

    iconGlyph: {
        if (VolumeService.sinkMuted)
            return IconConfig.volumeMute;
        if (VolumeService.sinkVolume === 0)
            return IconConfig.volumeEmpty;
        if (VolumeService.sinkVolume < 0.5)
            return IconConfig.volumeLow;
        return IconConfig.volumeHigh;
    }
    labelText: VolumeService.sinkMuted ? "muted" : Math.round(VolumeService.sinkVolume * 100) + "%"
    panelName: "volumePanel"
    showLabel: baseShowLabel || peekActive

    Connections {
        function onSinkMutedChanged() {
            peekTimer.restart();
        }
        function onSinkVolumeChanged() {
            peekTimer.restart();
        }

        enabled: root.peekReady
        target: VolumeService
    }
    Timer {
        id: peekTimer

        interval: BarConfig.volumePeekMs

        onRunningChanged: if (running)
            root.peekActive = true
        onTriggered: root.peekActive = false
    }
    Timer {
        interval: BarConfig.volumePeekReadyDelayMs
        running: true

        onTriggered: root.peekReady = true
    }
    MouseArea {
        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: PanelService.getPanel("volumePanel", root.screen)?.toggle(root)
        onWheel: function (wheel) {
            var up = wheel.angleDelta.y > 0;
            Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", up ? "5%+" : "5%-"]);
        }
    }
}
