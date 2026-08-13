pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

import qs.core
import qs.service
import qs.bar
import qs.components
import qs.controlcenter
import qs.config

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

                                // ---- Profile ----
                                Rectangle {
                                    id: profileCard

                                    property string _uptime: ""

                                    border.color: ColorConfig.accent
                                    border.width: ControlCenterConfig.profileBorderWidth
                                    color: ColorConfig.overlay
                                    height: profileMainCol.implicitHeight + ControlCenterConfig.profileVerticalPadding
                                    radius: ControlCenterConfig.profileRadius
                                    width: parent.width

                                    Process {
                                        command: ["uptime", "-p"]
                                        running: true

                                        stdout: StdioCollector {
                                            onStreamFinished: profileCard._uptime = text.trim().replace(/^up /, "")
                                        }
                                    }
                                    Process {
                                        id: settingsProc

                                        command: ["keqing-shell", "settings"]
                                        running: false
                                    }
                                    Column {
                                        id: profileMainCol

                                        spacing: ControlCenterConfig.profileContentSpacing
                                        y: ControlCenterConfig.profileTopPadding

                                        anchors {
                                            left: parent.left
                                            leftMargin: ControlCenterConfig.profileHorizontalPadding
                                            right: parent.right
                                            rightMargin: ControlCenterConfig.profileHorizontalPadding
                                        }
                                        Item {
                                            height: profileAvatar.height + ControlCenterConfig.profileAvatarGap + profileInfoCol.implicitHeight
                                            width: parent.width

                                            // avatar
                                            RoundImage {
                                                id: profileAvatar

                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.top: parent.top
                                                borderWidth: BarConfig.logoBorderWidth
                                                height: ControlCenterConfig.profileAvatarSize
                                                source: GlobalConfig.userPfp
                                                width: ControlCenterConfig.profileAvatarSize
                                            }

                                            // info
                                            Column {
                                                id: profileInfoCol

                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.top: profileAvatar.bottom
                                                anchors.topMargin: ControlCenterConfig.profileAvatarGap
                                                spacing: ControlCenterConfig.profileInfoSpacing

                                                Text {
                                                    color: ColorConfig.text
                                                    font.bold: true
                                                    font.family: FontConfig.fontFamily
                                                    font.pixelSize: FontConfig.fontBody + 1
                                                    horizontalAlignment: Text.AlignHCenter
                                                    text: GlobalConfig.user
                                                    width: ControlCenterConfig.profileInfoTextWidth
                                                }
                                                Text {
                                                    color: ColorConfig.textDim
                                                    elide: Text.ElideRight
                                                    font.family: FontConfig.fontFamily
                                                    font.pixelSize: FontConfig.fontBody - 1
                                                    horizontalAlignment: Text.AlignHCenter
                                                    text: profileCard._uptime
                                                    width: ControlCenterConfig.profileInfoTextWidth
                                                }
                                            }

                                            // settings
                                            Text {
                                                anchors.right: parent.right
                                                anchors.top: parent.top
                                                color: settingsHover.containsMouse ? ColorConfig.text : ColorConfig.textDim
                                                font.family: IconConfig.fontFamily
                                                font.pixelSize: FontConfig.fontProfileSettings
                                                text: IconConfig.settings

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: GlobalConfig.animationFast
                                                    }
                                                }

                                                MouseArea {
                                                    id: settingsHover

                                                    anchors.fill: parent
                                                    anchors.margins: -ControlCenterConfig.profileSettingsHitPadding
                                                    cursorShape: Qt.PointingHandCursor
                                                    hoverEnabled: true

                                                    onClicked: settingsProc.running = true
                                                }
                                            }
                                        }
                                    }
                                }

                                // ---- Battery ----
                                Item {
                                    id: batteryCard

                                    clip: true
                                    height: BatteryService.detected ? batteryCardRect.height : 0
                                    visible: height > 0 || BatteryService.detected
                                    width: parent.width

                                    function formatTime(seconds) {
                                        if (!seconds || seconds <= 0)
                                            return "";
                                        var h = Math.floor(seconds / 3600);
                                        var m = Math.floor((seconds % 3600) / 60);
                                        return h + " h " + m + " min";
                                    }

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: GlobalConfig.animationNormal
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Rectangle {
                                        id: batteryCardRect

                                        border.color: ColorConfig.accent
                                        border.width: ControlCenterConfig.cardBorderWidth
                                        color: ColorConfig.overlay
                                        height: ControlCenterConfig.cardTopPadding + batteryHdr.height + ControlCenterConfig.cardHeaderContentGap + batRow.height + ControlCenterConfig.cardBottomPadding
                                        radius: ControlCenterConfig.cardRadius
                                        width: parent.width

                                        Item {
                                            id: batteryHdr

                                            height: ControlCenterConfig.cardHeaderHeight
                                            y: ControlCenterConfig.cardTopPadding

                                            anchors {
                                                left: parent.left
                                                leftMargin: ControlCenterConfig.cardHorizontalPadding
                                                right: parent.right
                                                rightMargin: ControlCenterConfig.cardHorizontalPadding
                                            }
                                            Text {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: ColorConfig.text
                                                font.bold: true
                                                font.family: FontConfig.fontFamily
                                                font.pixelSize: FontConfig.fontBody
                                                text: "Battery"
                                            }
                                        }
                                        Item {
                                            id: batteryContentArea

                                            height: batRow.height

                                            anchors {
                                                left: parent.left
                                                leftMargin: ControlCenterConfig.cardHorizontalPadding
                                                right: parent.right
                                                rightMargin: ControlCenterConfig.cardHorizontalPadding
                                                top: batteryHdr.bottom
                                                topMargin: ControlCenterConfig.cardHeaderContentGap
                                            }
                                            Column {
                                                id: batRow

                                                spacing: ControlCenterConfig.batteryRowSpacing

                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                }
                                                Row {
                                                    spacing: ControlCenterConfig.batteryHeaderSpacing
                                                    width: parent.width

                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        color: {
                                                            if (BatteryService.charging || BatteryService.allFull)
                                                                return ColorConfig.accent;
                                                            if (BatteryService.pct <= 15)
                                                                return "#F44747";
                                                            if (BatteryService.pct <= 30)
                                                                return "#E0A83A";
                                                            return ColorConfig.text;
                                                        }
                                                        font.family: IconConfig.fontFamily
                                                        font.pixelSize: FontConfig.fontCardIcon
                                                        text: {
                                                            if (BatteryService.charging || BatteryService.allFull)
                                                                return IconConfig.batteryCharging;
                                                            if (BatteryService.pct > 75)
                                                                return IconConfig.battery4;
                                                            if (BatteryService.pct > 50)
                                                                return IconConfig.battery3;
                                                            if (BatteryService.pct > 25)
                                                                return IconConfig.battery2;
                                                            return IconConfig.battery1;
                                                        }
                                                    }
                                                    Column {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        spacing: ControlCenterConfig.batteryTextSpacing

                                                        Text {
                                                            color: ColorConfig.text
                                                            font.bold: true
                                                            font.family: FontConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontBody + 1
                                                            text: "Battery " + BatteryService.pct + "%"
                                                        }
                                                        Text {
                                                            color: ColorConfig.textDim
                                                            font.family: FontConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontBody - 1
                                                            text: {
                                                                if (BatteryService.allFull)
                                                                    return "Full";
                                                                if (BatteryService.charging && BatteryService.battery) {
                                                                    var t = batteryCard.formatTime(BatteryService.battery.timeToFull);
                                                                    return t !== "" ? t + " to full" : "Charging";
                                                                }
                                                                if (BatteryService.battery) {
                                                                    var te = batteryCard.formatTime(BatteryService.battery.timeToEmpty);
                                                                    return te !== "" ? te + " remaining" : "Discharging";
                                                                }
                                                                return "";
                                                            }
                                                        }
                                                    }
                                                }
                                                Rectangle {
                                                    color: ColorConfig.textAlpha10
                                                    height: ControlCenterConfig.batteryBarHeight
                                                    radius: ControlCenterConfig.batteryBarRadius
                                                    width: parent.width

                                                    Rectangle {
                                                        color: {
                                                            if (BatteryService.charging || BatteryService.allFull)
                                                                return ColorConfig.accent;
                                                            if (BatteryService.pct <= 15)
                                                                return "#F44747";
                                                            if (BatteryService.pct <= 30)
                                                                return "#E0A83A";
                                                            return ColorConfig.accent;
                                                        }
                                                        height: parent.height
                                                        radius: parent.radius
                                                        width: Math.max(radius * 2, parent.width * Math.min(BatteryService.pct, 100) / 100)

                                                        Behavior on color {
                                                            ColorAnimation {
                                                                duration: ControlCenterConfig.batteryColorAnimMs
                                                            }
                                                        }
                                                        Behavior on width {
                                                            NumberAnimation {
                                                                duration: ControlCenterConfig.batteryWidthAnimMs
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // ---- System stats ----
                                Item {
                                    id: systemStatsCard

                                    clip: true
                                    height: systemStatsCardRect.height
                                    visible: height > 0
                                    width: parent.width

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: GlobalConfig.animationNormal
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Rectangle {
                                        id: systemStatsCardRect

                                        border.color: ColorConfig.accent
                                        border.width: ControlCenterConfig.cardBorderWidth
                                        color: ColorConfig.overlay
                                        height: ControlCenterConfig.cardTopPadding + systemStatsHdr.height + ControlCenterConfig.cardHeaderContentGap + statsCol.implicitHeight + ControlCenterConfig.cardBottomPadding
                                        radius: ControlCenterConfig.cardRadius
                                        width: parent.width

                                        Item {
                                            id: systemStatsHdr

                                            height: ControlCenterConfig.cardHeaderHeight
                                            y: ControlCenterConfig.cardTopPadding

                                            anchors {
                                                left: parent.left
                                                leftMargin: ControlCenterConfig.cardHorizontalPadding
                                                right: parent.right
                                                rightMargin: ControlCenterConfig.cardHorizontalPadding
                                            }
                                            Text {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: ColorConfig.text
                                                font.bold: true
                                                font.family: FontConfig.fontFamily
                                                font.pixelSize: FontConfig.fontBody
                                                text: "System"
                                            }
                                        }
                                        Item {
                                            id: systemStatsContentArea

                                            height: statsCol.implicitHeight

                                            anchors {
                                                left: parent.left
                                                leftMargin: ControlCenterConfig.cardHorizontalPadding
                                                right: parent.right
                                                rightMargin: ControlCenterConfig.cardHorizontalPadding
                                                top: systemStatsHdr.bottom
                                                topMargin: ControlCenterConfig.cardHeaderContentGap
                                            }
                                            Column {
                                                id: statsCol

                                                spacing: ControlCenterConfig.statsSpacing

                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                }
                                                Row {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    spacing: ControlCenterConfig.statsColumnGap

                                                    Column {
                                                        spacing: ControlCenterConfig.statsGaugeLabelSpacing

                                                        ArcGauge {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            arcColor: "#ef4444"
                                                            icon: IconConfig.cpu
                                                            value: SystemStatService.cpuUsage
                                                        }
                                                        Text {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            color: ColorConfig.textDim
                                                            font.family: FontConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontBody - 1
                                                            text: "CPU"
                                                        }
                                                    }
                                                    Column {
                                                        spacing: ControlCenterConfig.statsGaugeLabelSpacing
                                                        visible: SystemStatService.gpuAvailable
                                                        width: visible ? implicitWidth : 0

                                                        ArcGauge {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            arcColor: "#a855f7"
                                                            icon: IconConfig.gpu
                                                            value: SystemStatService.gpuUsage
                                                        }
                                                        Text {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            color: ColorConfig.textDim
                                                            font.family: FontConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontBody - 1
                                                            text: "GPU"
                                                        }
                                                    }
                                                    Column {
                                                        spacing: ControlCenterConfig.statsGaugeLabelSpacing

                                                        ArcGauge {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            arcColor: "#3b82f6"
                                                            icon: IconConfig.settings
                                                            value: SystemStatService.memPercent
                                                        }
                                                        Text {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            color: ColorConfig.textDim
                                                            font.family: FontConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontBody - 1
                                                            text: "RAM"
                                                        }
                                                    }
                                                    Column {
                                                        spacing: ControlCenterConfig.statsGaugeLabelSpacing

                                                        ArcGauge {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            arcColor: "#22c55e"
                                                            icon: IconConfig.folder
                                                            value: SystemStatService.diskRootPct
                                                        }
                                                        Text {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            color: ColorConfig.textDim
                                                            font.family: FontConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontBody - 1
                                                            text: "DISK"
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // ---- CPU temperature ----
                                Item {
                                    id: cpuTempCard

                                    property int _coreCount: 0
                                    readonly property bool _hasCores: _coreCount > 0
                                    readonly property int _rows: Math.ceil(_coreCount / 2)

                                    clip: true
                                    height: cpuTempCardRect.height
                                    visible: height > 0
                                    width: parent.width

                                    Component.onCompleted: {
                                        var vals = SystemStatService.intelTempValues;
                                        if (vals && vals.length > 0) {
                                            cpuTempCard._coreCount = vals.length;
                                            for (var i = 0; i < vals.length; i++)
                                                coreModel.append({
                                                    temp: vals[i]
                                                });
                                        }
                                    }

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: GlobalConfig.animationNormal
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    ListModel {
                                        id: coreModel
                                    }
                                    Connections {
                                        function onIntelTempValuesChanged() {
                                            var vals = SystemStatService.intelTempValues;
                                            if (!vals || vals.length === 0)
                                                return;
                                            if (coreModel.count === 0) {
                                                cpuTempCard._coreCount = vals.length;
                                                for (var i = 0; i < vals.length; i++)
                                                    coreModel.append({
                                                        temp: vals[i]
                                                    });
                                            } else {
                                                for (var i = 0; i < Math.min(vals.length, coreModel.count); i++)
                                                    coreModel.setProperty(i, "temp", vals[i]);
                                            }
                                        }

                                        target: SystemStatService
                                    }

                                    Rectangle {
                                        id: cpuTempCardRect

                                        border.color: ColorConfig.accent
                                        border.width: ControlCenterConfig.cardBorderWidth
                                        color: ColorConfig.overlay
                                        height: ControlCenterConfig.cardTopPadding + cpuTempHdr.height + ControlCenterConfig.cardHeaderContentGap + cpuTempContentHeight + ControlCenterConfig.cardBottomPadding
                                        radius: ControlCenterConfig.cardRadius
                                        width: parent.width

                                        readonly property real cpuTempContentHeight: ControlCenterConfig.tempRowHeight + (cpuTempCard._hasCores ? ControlCenterConfig.cpuTempGridTopMargin + cpuTempCard._rows * ControlCenterConfig.cpuCoreItemHeight + Math.max(0, cpuTempCard._rows - 1) * ControlCenterConfig.cpuCoreRowSpacing : 0)

                                        Item {
                                            id: cpuTempHdr

                                            height: ControlCenterConfig.cardHeaderHeight
                                            y: ControlCenterConfig.cardTopPadding

                                            anchors {
                                                left: parent.left
                                                leftMargin: ControlCenterConfig.cardHorizontalPadding
                                                right: parent.right
                                                rightMargin: ControlCenterConfig.cardHorizontalPadding
                                            }
                                            Text {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: ColorConfig.text
                                                font.bold: true
                                                font.family: FontConfig.fontFamily
                                                font.pixelSize: FontConfig.fontBody
                                                text: "CPU Temperature"
                                            }
                                        }
                                        Item {
                                            id: cpuTempContentArea

                                            height: cpuTempCardRect.cpuTempContentHeight

                                            anchors {
                                                left: parent.left
                                                leftMargin: ControlCenterConfig.cardHorizontalPadding
                                                right: parent.right
                                                rightMargin: ControlCenterConfig.cardHorizontalPadding
                                                top: cpuTempHdr.bottom
                                                topMargin: ControlCenterConfig.cardHeaderContentGap
                                            }
                                            Text {
                                                id: avgTemp

                                                color: {
                                                    var t = SystemStatService.cpuTempC;
                                                    if (t >= 85)
                                                        return "#ef4444";
                                                    if (t >= 70)
                                                        return "#f97316";
                                                    return ColorConfig.text;
                                                }
                                                font.bold: true
                                                font.family: FontConfig.fontFamily
                                                font.pixelSize: FontConfig.fontTempValue
                                                text: SystemStatService.cpuTempC + " °C"

                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                }
                                            }
                                            Grid {
                                                id: coreGrid

                                                columnSpacing: ControlCenterConfig.cpuCoreColumnSpacing
                                                columns: ControlCenterConfig.cpuCoreColumns
                                                rowSpacing: ControlCenterConfig.cpuCoreRowSpacing
                                                visible: cpuTempCard._hasCores

                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                    top: avgTemp.bottom
                                                    topMargin: ControlCenterConfig.cpuTempGridTopMargin
                                                }
                                                Repeater {
                                                    model: coreModel

                                                    Rectangle {
                                                        id: coreItem

                                                        required property int index
                                                        required property real temp

                                                        color: ColorConfig.textAlpha08
                                                        height: ControlCenterConfig.cpuCoreItemHeight
                                                        radius: ControlCenterConfig.cpuCoreItemRadius
                                                        width: (coreGrid.width - coreGrid.columnSpacing) / ControlCenterConfig.cpuCoreColumns

                                                        Text {
                                                            color: ColorConfig.textDim
                                                            font.family: FontConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontBody - 1
                                                            text: "Core " + coreItem.index

                                                            anchors {
                                                                left: parent.left
                                                                leftMargin: ControlCenterConfig.cpuCoreTextMargin
                                                                verticalCenter: parent.verticalCenter
                                                            }
                                                        }
                                                        Text {
                                                            color: {
                                                                if (coreItem.temp >= 85)
                                                                    return "#ef4444";
                                                                if (coreItem.temp >= 70)
                                                                    return "#f97316";
                                                                return ColorConfig.text;
                                                            }
                                                            font.bold: true
                                                            font.family: FontConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontBody - 1
                                                            text: Math.round(coreItem.temp) + " °C"

                                                            anchors {
                                                                right: parent.right
                                                                rightMargin: ControlCenterConfig.cpuCoreTextMargin
                                                                verticalCenter: parent.verticalCenter
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // ---- GPU temperature ----
                                Item {
                                    id: gpuTempCard

                                    clip: true
                                    height: SystemStatService.gpuAvailable ? gpuTempCardRect.height : 0
                                    visible: height > 0 || SystemStatService.gpuAvailable
                                    width: parent.width

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: GlobalConfig.animationNormal
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Rectangle {
                                        id: gpuTempCardRect

                                        border.color: ColorConfig.accent
                                        border.width: ControlCenterConfig.cardBorderWidth
                                        color: ColorConfig.overlay
                                        height: ControlCenterConfig.cardTopPadding + gpuTempHdr.height + ControlCenterConfig.cardHeaderContentGap + ControlCenterConfig.tempRowHeight + ControlCenterConfig.cardBottomPadding
                                        radius: ControlCenterConfig.cardRadius
                                        width: parent.width

                                        Item {
                                            id: gpuTempHdr

                                            height: ControlCenterConfig.cardHeaderHeight
                                            y: ControlCenterConfig.cardTopPadding

                                            anchors {
                                                left: parent.left
                                                leftMargin: ControlCenterConfig.cardHorizontalPadding
                                                right: parent.right
                                                rightMargin: ControlCenterConfig.cardHorizontalPadding
                                            }
                                            Text {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: ColorConfig.text
                                                font.bold: true
                                                font.family: FontConfig.fontFamily
                                                font.pixelSize: FontConfig.fontBody
                                                text: "GPU Temperature"
                                            }
                                        }
                                        Item {
                                            id: gpuTempContentArea

                                            height: ControlCenterConfig.tempRowHeight

                                            anchors {
                                                left: parent.left
                                                leftMargin: ControlCenterConfig.cardHorizontalPadding
                                                right: parent.right
                                                rightMargin: ControlCenterConfig.cardHorizontalPadding
                                                top: gpuTempHdr.bottom
                                                topMargin: ControlCenterConfig.cardHeaderContentGap
                                            }
                                            Text {
                                                color: {
                                                    var t = SystemStatService.gpuTempC;
                                                    if (t >= 85)
                                                        return "#ef4444";
                                                    if (t >= 70)
                                                        return "#f97316";
                                                    return ColorConfig.text;
                                                }
                                                font.bold: true
                                                font.family: FontConfig.fontFamily
                                                font.pixelSize: FontConfig.fontTempValue
                                                text: SystemStatService.gpuTempC + " °C"

                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                }
                                            }
                                        }
                                    }
                                }

                                // ---- Media ----
                                Item {
                                    id: mediaCard

                                    readonly property int _thumbSize: ControlCenterConfig.mediaThumbSize

                                    clip: true
                                    height: mediaCardRect.height
                                    visible: height > 0
                                    width: parent.width

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: GlobalConfig.animationNormal
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Rectangle {
                                        id: mediaCardRect

                                        border.color: ColorConfig.accent
                                        border.width: ControlCenterConfig.cardBorderWidth
                                        color: ColorConfig.overlay
                                        height: ControlCenterConfig.cardTopPadding + mediaHdr.height + ControlCenterConfig.cardHeaderContentGap + (ctrlRow.y + ctrlRow.height) + ControlCenterConfig.cardBottomPadding
                                        radius: ControlCenterConfig.cardRadius
                                        width: parent.width

                                        Item {
                                            id: mediaHdr

                                            height: ControlCenterConfig.cardHeaderHeight
                                            y: ControlCenterConfig.cardTopPadding

                                            anchors {
                                                left: parent.left
                                                leftMargin: ControlCenterConfig.cardHorizontalPadding
                                                right: parent.right
                                                rightMargin: ControlCenterConfig.cardHorizontalPadding
                                            }
                                            Text {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: ColorConfig.text
                                                font.bold: true
                                                font.family: FontConfig.fontFamily
                                                font.pixelSize: FontConfig.fontBody
                                                text: "Media"
                                            }
                                        }
                                        Item {
                                            id: mediaContentArea

                                            height: ctrlRow.y + ctrlRow.height

                                            anchors {
                                                left: parent.left
                                                leftMargin: ControlCenterConfig.cardHorizontalPadding
                                                right: parent.right
                                                rightMargin: ControlCenterConfig.cardHorizontalPadding
                                                top: mediaHdr.bottom
                                                topMargin: ControlCenterConfig.cardHeaderContentGap
                                            }
                                            Item {
                                                id: topRow

                                                height: mediaCard._thumbSize

                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                }
                                                Rectangle {
                                                    id: thumb

                                                    clip: true
                                                    color: ColorConfig.overlay
                                                    height: mediaCard._thumbSize
                                                    radius: ControlCenterConfig.mediaThumbRadius
                                                    width: mediaCard._thumbSize

                                                    anchors {
                                                        left: parent.left
                                                        verticalCenter: parent.verticalCenter
                                                    }
                                                    Image {
                                                        anchors.fill: parent
                                                        fillMode: Image.PreserveAspectCrop
                                                        source: MediaService.trackArtUrl
                                                        visible: MediaService.trackArtUrl !== ""
                                                    }
                                                    Text {
                                                        anchors.centerIn: parent
                                                        color: ColorConfig.textDim
                                                        font.family: IconConfig.fontFamily
                                                        font.pixelSize: FontConfig.fontCardIcon
                                                        text: IconConfig.musicNote
                                                        visible: MediaService.trackArtUrl === ""
                                                    }
                                                }
                                                Column {
                                                    id: titleCol

                                                    spacing: ControlCenterConfig.mediaTitleSpacing

                                                    anchors {
                                                        left: thumb.right
                                                        leftMargin: ControlCenterConfig.mediaTitleLeftMargin
                                                        right: parent.right
                                                        verticalCenter: parent.verticalCenter
                                                    }
                                                    MarqueeText {
                                                        color: ColorConfig.text
                                                        fontFamily: FontConfig.fontFamily
                                                        fontSize: FontConfig.fontBody
                                                        text: MediaService.currentPlayer ? (MediaService.trackTitle !== "" ? MediaService.trackTitle : "Unknown") : "Nothing playing"
                                                        width: parent.width
                                                    }
                                                    MarqueeText {
                                                        color: ColorConfig.textDim
                                                        fontFamily: FontConfig.fontFamily
                                                        fontSize: FontConfig.fontBody - 1
                                                        text: MediaService.currentPlayer ? (MediaService.trackArtist !== "" ? MediaService.trackArtist : "Unknown Artist") : ""
                                                        width: parent.width
                                                    }
                                                }
                                            }
                                            Item {
                                                id: progressRow

                                                height: ControlCenterConfig.mediaProgressRowHeight

                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                    top: topRow.bottom
                                                    topMargin: ControlCenterConfig.mediaProgressTopMargin
                                                }
                                                Text {
                                                    color: ColorConfig.textDim
                                                    font.family: FontConfig.fontFamily
                                                    font.pixelSize: FontConfig.fontBody - 1
                                                    text: MediaService.positionString + " / " + MediaService.lengthString

                                                    anchors {
                                                        horizontalCenter: parent.horizontalCenter
                                                        verticalCenter: parent.verticalCenter
                                                    }
                                                }
                                            }
                                            Item {
                                                id: ctrlRow

                                                height: ControlCenterConfig.mediaCtrlRowHeight

                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                    top: progressRow.bottom
                                                    topMargin: ControlCenterConfig.mediaCtrlTopMargin
                                                }
                                                Row {
                                                    anchors.centerIn: parent
                                                    spacing: ControlCenterConfig.mediaCtrlSpacing

                                                    Rectangle {
                                                        color: prevMa.containsMouse ? ColorConfig.overlay : "transparent"
                                                        height: ControlCenterConfig.mediaSideBtnSize
                                                        radius: ControlCenterConfig.mediaSideBtnRadius
                                                        width: ControlCenterConfig.mediaSideBtnSize

                                                        Text {
                                                            anchors.centerIn: parent
                                                            color: MediaService.canGoPrevious ? ColorConfig.text : ColorConfig.textDim
                                                            font.family: IconConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontMediaControl
                                                            text: IconConfig.playerPrev
                                                        }
                                                        MouseArea {
                                                            id: prevMa

                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            enabled: MediaService.canGoPrevious
                                                            hoverEnabled: true

                                                            onClicked: MediaService.previous()
                                                        }
                                                    }
                                                    Rectangle {
                                                        color: playMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
                                                        height: ControlCenterConfig.mediaPlayBtnSize
                                                        radius: ControlCenterConfig.mediaPlayBtnRadius
                                                        width: ControlCenterConfig.mediaPlayBtnSize

                                                        Text {
                                                            anchors.centerIn: parent
                                                            color: ColorConfig.text
                                                            font.family: IconConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontMediaControl
                                                            text: MediaService.isPlaying ? IconConfig.playerPause : IconConfig.playerPlay
                                                        }
                                                        MouseArea {
                                                            id: playMa

                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            hoverEnabled: true

                                                            onClicked: MediaService.playPause()
                                                        }
                                                    }
                                                    Rectangle {
                                                        color: nextMa.containsMouse ? ColorConfig.overlay : "transparent"
                                                        height: ControlCenterConfig.mediaSideBtnSize
                                                        radius: ControlCenterConfig.mediaSideBtnRadius
                                                        width: ControlCenterConfig.mediaSideBtnSize

                                                        Text {
                                                            anchors.centerIn: parent
                                                            color: MediaService.canGoNext ? ColorConfig.text : ColorConfig.textDim
                                                            font.family: IconConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontMediaControl
                                                            text: IconConfig.playerNext
                                                        }
                                                        MouseArea {
                                                            id: nextMa

                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            enabled: MediaService.canGoNext
                                                            hoverEnabled: true

                                                            onClicked: MediaService.next()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // ---- Volume ----
                                Item {
                                    id: volumeCard

                                    clip: true
                                    height: volumeCardRect.height
                                    visible: height > 0
                                    width: parent.width

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: GlobalConfig.animationNormal
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Rectangle {
                                        id: volumeCardRect

                                        border.color: ColorConfig.accent
                                        border.width: ControlCenterConfig.cardBorderWidth
                                        color: ColorConfig.overlay
                                        height: ControlCenterConfig.cardTopPadding + volumeHdr.height + ControlCenterConfig.cardHeaderContentGap + volumeColumn.implicitHeight + ControlCenterConfig.cardBottomPadding
                                        radius: ControlCenterConfig.cardRadius
                                        width: parent.width

                                        Item {
                                            id: volumeHdr

                                            height: ControlCenterConfig.cardHeaderHeight
                                            y: ControlCenterConfig.cardTopPadding

                                            anchors {
                                                left: parent.left
                                                leftMargin: ControlCenterConfig.cardHorizontalPadding
                                                right: parent.right
                                                rightMargin: ControlCenterConfig.cardHorizontalPadding
                                            }
                                            Text {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: ColorConfig.text
                                                font.bold: true
                                                font.family: FontConfig.fontFamily
                                                font.pixelSize: FontConfig.fontBody
                                                text: "Volume"
                                            }
                                        }
                                        Item {
                                            id: volumeContentArea

                                            height: volumeColumn.implicitHeight

                                            anchors {
                                                left: parent.left
                                                leftMargin: ControlCenterConfig.cardHorizontalPadding
                                                right: parent.right
                                                rightMargin: ControlCenterConfig.cardHorizontalPadding
                                                top: volumeHdr.bottom
                                                topMargin: ControlCenterConfig.cardHeaderContentGap
                                            }
                                            Column {
                                                id: volumeColumn

                                                spacing: ControlCenterConfig.volumeCardSpacing

                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                }

                                                // Output
                                                Column {
                                                    id: outputRow

                                                    spacing: ControlCenterConfig.volumeRowSpacing
                                                    width: parent.width

                                                    Row {
                                                        spacing: ControlCenterConfig.volumeLabelRowSpacing
                                                        width: parent.width

                                                        Text {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            color: ColorConfig.text
                                                            font.bold: true
                                                            font.family: FontConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontBody
                                                            text: "Output"
                                                        }
                                                        Text {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            color: ColorConfig.textDim
                                                            elide: Text.ElideRight
                                                            font.family: FontConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontBody
                                                            text: {
                                                                var d = VolumeService.sink ? (VolumeService.sink.description || VolumeService.sink.name || "") : "";
                                                                return d ? " — " + d : "";
                                                            }
                                                            width: Math.min(implicitWidth, ControlCenterConfig.volumeDeviceTextMaxWidth)
                                                        }
                                                    }
                                                    Item {
                                                        height: ControlCenterConfig.volumeSliderRowHeight
                                                        width: parent.width

                                                        SliderBar {
                                                            dimmed: VolumeService.sinkMuted
                                                            height: ControlCenterConfig.volumeSliderHeight
                                                            maxValue: 100
                                                            value: VolumeService.sinkMuted ? 0 : VolumeService.sinkVolume * 100

                                                            onScrubbed: v => VolumeService.setSinkVolume(v / 100)

                                                            anchors {
                                                                left: parent.left
                                                                right: outputPct.left
                                                                rightMargin: ControlCenterConfig.volumeSliderPctGap
                                                                verticalCenter: parent.verticalCenter
                                                            }
                                                        }
                                                        Text {
                                                            id: outputPct

                                                            color: ColorConfig.textDim
                                                            font.family: FontConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontBody
                                                            horizontalAlignment: Text.AlignRight
                                                            text: VolumeService.sinkMuted ? "muted" : Math.round(VolumeService.sinkVolume * 100) + "%"
                                                            width: ControlCenterConfig.volumePctTextWidth

                                                            anchors {
                                                                right: outputMuteBtn.left
                                                                rightMargin: ControlCenterConfig.volumePctMuteGap
                                                                verticalCenter: parent.verticalCenter
                                                            }
                                                        }
                                                        Rectangle {
                                                            id: outputMuteBtn

                                                            color: outputMuteMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
                                                            height: ControlCenterConfig.volumeMuteBtnSize
                                                            radius: ControlCenterConfig.volumeMuteBtnRadius
                                                            width: ControlCenterConfig.volumeMuteBtnSize

                                                            anchors {
                                                                right: parent.right
                                                                verticalCenter: parent.verticalCenter
                                                            }
                                                            Text {
                                                                anchors.centerIn: parent
                                                                color: ColorConfig.text
                                                                font.family: IconConfig.fontFamily
                                                                font.pixelSize: FontConfig.fontPanelActionIcon
                                                                text: VolumeService.sinkMuted ? IconConfig.volumeMute : VolumeService.sinkVolume === 0 ? IconConfig.volumeEmpty : VolumeService.sinkVolume < 0.5 ? IconConfig.volumeLow : IconConfig.volumeHigh
                                                            }
                                                            MouseArea {
                                                                id: outputMuteMa

                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                hoverEnabled: true

                                                                onClicked: VolumeService.setSinkMuted(!VolumeService.sinkMuted)
                                                            }
                                                        }
                                                    }
                                                }

                                                // Input
                                                Column {
                                                    id: inputRow

                                                    spacing: ControlCenterConfig.volumeRowSpacing
                                                    width: parent.width

                                                    Row {
                                                        spacing: ControlCenterConfig.volumeLabelRowSpacing
                                                        width: parent.width

                                                        Text {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            color: ColorConfig.text
                                                            font.bold: true
                                                            font.family: FontConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontBody
                                                            text: "Input"
                                                        }
                                                        Text {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            color: ColorConfig.textDim
                                                            elide: Text.ElideRight
                                                            font.family: FontConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontBody
                                                            text: {
                                                                var d = VolumeService.source ? (VolumeService.source.description || VolumeService.source.name || "") : "";
                                                                return d ? " — " + d : "";
                                                            }
                                                            width: Math.min(implicitWidth, ControlCenterConfig.volumeDeviceTextMaxWidth)
                                                        }
                                                    }
                                                    Item {
                                                        height: ControlCenterConfig.volumeSliderRowHeight
                                                        width: parent.width

                                                        SliderBar {
                                                            dimmed: VolumeService.sourceMuted
                                                            height: ControlCenterConfig.volumeSliderHeight
                                                            maxValue: 100
                                                            value: VolumeService.sourceMuted ? 0 : VolumeService.sourceVolume * 100

                                                            onScrubbed: v => VolumeService.setSourceVolume(v / 100)

                                                            anchors {
                                                                left: parent.left
                                                                right: inputPct.left
                                                                rightMargin: ControlCenterConfig.volumeSliderPctGap
                                                                verticalCenter: parent.verticalCenter
                                                            }
                                                        }
                                                        Text {
                                                            id: inputPct

                                                            color: ColorConfig.textDim
                                                            font.family: FontConfig.fontFamily
                                                            font.pixelSize: FontConfig.fontBody
                                                            horizontalAlignment: Text.AlignRight
                                                            text: VolumeService.sourceMuted ? "muted" : Math.round(VolumeService.sourceVolume * 100) + "%"
                                                            width: ControlCenterConfig.volumePctTextWidth

                                                            anchors {
                                                                right: inputMuteBtn.left
                                                                rightMargin: ControlCenterConfig.volumePctMuteGap
                                                                verticalCenter: parent.verticalCenter
                                                            }
                                                        }
                                                        Rectangle {
                                                            id: inputMuteBtn

                                                            color: inputMuteMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
                                                            height: ControlCenterConfig.volumeMuteBtnSize
                                                            radius: ControlCenterConfig.volumeMuteBtnRadius
                                                            width: ControlCenterConfig.volumeMuteBtnSize

                                                            anchors {
                                                                right: parent.right
                                                                verticalCenter: parent.verticalCenter
                                                            }
                                                            Text {
                                                                anchors.centerIn: parent
                                                                color: ColorConfig.text
                                                                font.family: IconConfig.fontFamily
                                                                font.pixelSize: FontConfig.fontPanelActionIcon
                                                                text: VolumeService.sourceMuted ? IconConfig.micOff : IconConfig.micOn
                                                            }
                                                            MouseArea {
                                                                id: inputMuteMa

                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                hoverEnabled: true

                                                                onClicked: VolumeService.setSourceMuted(!VolumeService.sourceMuted)
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
    }

    IpcHandler {
        function toggle() {
            root.toggle();
        }

        target: "controlcenter"
    }
}
