pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.overview.layout
import qs.modules.overview.service
import qs.config

Item {
    id: root

    readonly property int activeWorkspaceId: monitorData?.activeWorkspace?.id ?? 1
    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1
    property bool initialized: false
    readonly property var monitorData: monitors.find(m => m.id === monitorId) ?? null
    required property int monitorId
    readonly property var monitors: HyprlandManager.monitors
    readonly property real overviewScale: OverviewConfig.scale
    readonly property var windowByAddress: HyprlandManager.windowByAddress
    property int windowDraggingZ: OverviewConfig.windowDraggingZ
    property int windowZ: 1
    readonly property real workspaceAvailableHeight: Math.max(workspaceImplicitHeight, 1)
    readonly property real workspaceAvailableWidth: Math.max(workspaceImplicitWidth, 1)
    readonly property int workspaceGroup: Math.floor((activeWorkspaceId - 1) / workspacesShown)
    readonly property real workspaceImplicitHeight: Math.round(_sourceWorkAreaHeight(monitorData) * overviewScale)
    readonly property real workspaceImplicitWidth: Math.round(_sourceWorkAreaWidth(monitorData) * overviewScale)
    readonly property real workspaceSpacingPx: Math.round(OverviewConfig.workspaceSpacing)
    property int workspaceZ: 0
    readonly property int workspacesShown: OverviewConfig.rows * OverviewConfig.columns

    signal requestClose

    function _monitorSnapshot(m) {
        return {
            id: m?.id ?? -1,
            x: m?.x ?? 0,
            y: m?.y ?? 0,
            width: m?.width ?? 1920,
            height: m?.height ?? 1080,
            scale: m?.scale ?? 1,
            transform: m?.transform ?? 0,
            reserved: m?.reserved ?? [0, 0, 0, 0]
        };
    }
    function _previewScale(sourceMonitor) {
        const srcW = Math.max(_sourceWorkAreaWidth(sourceMonitor), 1);
        const srcH = Math.max(_sourceWorkAreaHeight(sourceMonitor), 1);
        return Math.min(workspaceAvailableWidth / srcW, workspaceAvailableHeight / srcH);
    }
    function _sourceWorkAreaHeight(m) {
        return (m?.transform % 2 === 1) ? (m?.width ?? 1080) / (m?.scale ?? 1) - (m?.reserved?.[1] ?? 0) - (m?.reserved?.[3] ?? 0) : (m?.height ?? 1080) / (m?.scale ?? 1) - (m?.reserved?.[1] ?? 0) - (m?.reserved?.[3] ?? 0);
    }
    function _sourceWorkAreaWidth(m) {
        return (m?.transform % 2 === 1) ? (m?.height ?? 1920) / (m?.scale ?? 1) - (m?.reserved?.[0] ?? 0) - (m?.reserved?.[2] ?? 0) : (m?.width ?? 1920) / (m?.scale ?? 1) - (m?.reserved?.[0] ?? 0) - (m?.reserved?.[2] ?? 0);
    }
    function stepWorkspace(delta) {
        const minId = workspaceGroup * workspacesShown + 1;
        const maxId = (workspaceGroup + 1) * workspacesShown;
        let targetId = activeWorkspaceId + delta;
        if (targetId < minId)
            targetId = maxId;
        else if (targetId > maxId)
            targetId = minId;
        Hyprland.dispatch("workspace " + targetId);
    }

    implicitHeight: overviewBackground.implicitHeight + OverviewConfig.elevationMargin * 2
    implicitWidth: overviewBackground.implicitWidth + OverviewConfig.elevationMargin * 2

    Component.onCompleted: Qt.callLater(() => root.initialized = true)

    RectangularShadow {
        anchors.fill: overviewBackground
        blur: OverviewConfig.shadowBlurFactor * OverviewConfig.elevationMargin
        cached: true
        color: ColorConfig.overlay
        offset: Qt.vector2d(OverviewConfig.shadowOffsetX, OverviewConfig.shadowOffsetY)
        radius: OverviewConfig.shadowRadius
        spread: OverviewConfig.shadowSpread
    }
    Rectangle {
        id: overviewBackground

        property real padding: OverviewConfig.backgroundPadding

        anchors.fill: parent
        anchors.margins: OverviewConfig.elevationMargin
        border.color: ColorConfig.accent
        border.width: OverviewConfig.backgroundBorderWidth
        color: ColorConfig.fieldBg
        implicitHeight: workspaceColumnLayout.implicitHeight + padding * 2
        implicitWidth: workspaceColumnLayout.implicitWidth + padding * 2
        opacity: OverviewConfig.backgroundOpacity
        radius: OverviewConfig.screenRounding * root.overviewScale + padding

        ColumnLayout {
            id: workspaceColumnLayout

            spacing: root.workspaceSpacingPx
            x: Math.round(overviewBackground.padding)
            y: Math.round(overviewBackground.padding)
            z: root.workspaceZ

            Repeater {
                model: OverviewConfig.rows

                delegate: RowLayout {
                    id: row

                    required property int index
                    property int rowIndex: index

                    spacing: root.workspaceSpacingPx

                    Repeater {
                        model: OverviewConfig.columns

                        Rectangle {
                            id: workspace

                            property int colIndex: index
                            property color defaultWorkspaceColor: ColorConfig.fieldBg
                            readonly property bool hasWindows: {
                                const wba = root.windowByAddress;
                                for (const addr in wba) {
                                    if ((wba[addr]?.workspace?.id ?? -1) === workspaceValue)
                                        return true;
                                }
                                return false;
                            }
                            property color hoveredBorderColor: ColorConfig.textAlpha08
                            property bool hoveredWhileDragging: false
                            property color hoveredWorkspaceColor: ColorConfig.fieldBg
                            required property int index
                            property int workspaceValue: root.workspaceGroup * root.workspacesShown + (parent?.rowIndex ?? 0) * OverviewConfig.columns + colIndex + 1

                            border.color: hoveredWhileDragging ? hoveredBorderColor : ColorConfig.textAlpha18
                            border.width: OverviewConfig.workspaceBorderWidth
                            color: hoveredWhileDragging ? hoveredWorkspaceColor : defaultWorkspaceColor
                            implicitHeight: root.workspaceImplicitHeight
                            implicitWidth: root.workspaceImplicitWidth
                            radius: OverviewConfig.screenRounding * root.overviewScale

                            StyledText {
                                anchors.centerIn: parent
                                color: ColorConfig.text
                                horizontalAlignment: Text.AlignHCenter
                                opacity: 1 - OverviewConfig.workspaceNumberTextFade
                                text: workspaceValue
                                verticalAlignment: Text.AlignVCenter

                                font {
                                    family: FontConfig.fontFamily
                                    pixelSize: (OverviewConfig.workspaceNumberBaseSize * (root.monitorData?.scale ?? 1)) * root.overviewScale
                                    weight: Font.DemiBold
                                }
                            }
                            MouseArea {
                                id: workspaceArea

                                acceptedButtons: Qt.LeftButton
                                anchors.fill: parent

                                onClicked: mouse => {
                                    if (root.draggingTargetWorkspace === -1) {
                                        root.requestClose();
                                        HyprlandManager.switchToWorkspace(workspaceValue, mouse.modifiers);
                                    }
                                }
                            }
                            DropArea {
                                anchors.fill: parent

                                onEntered: {
                                    root.draggingTargetWorkspace = workspaceValue;
                                    if (root.draggingFromWorkspace == root.draggingTargetWorkspace)
                                        return;
                                    hoveredWhileDragging = true;
                                }
                                onExited: {
                                    hoveredWhileDragging = false;
                                    if (root.draggingTargetWorkspace == workspaceValue)
                                        root.draggingTargetWorkspace = -1;
                                }
                            }
                        }
                    }
                }
            }
        }
        Item {
            id: windowSpace

            height: Math.round(workspaceColumnLayout.implicitHeight)
            width: Math.round(workspaceColumnLayout.implicitWidth)
            x: Math.round(workspaceColumnLayout.x)
            y: Math.round(workspaceColumnLayout.y)

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                target: null

                onWheel: event => {
                    const deltaY = event.angleDelta.y;
                    if (!deltaY)
                        return;
                    root.stepWorkspace(deltaY > 0 ? -1 : 1);
                    event.accepted = true;
                }
            }
            Repeater {
                delegate: Window {
                    id: window

                    property var _srcMonitor: root.monitors.find(m => m.id === _srcMonitorId) ?? null
                    property int _srcMonitorId: windowData?.monitor ?? -1
                    property int _wsLocalIdx: ((windowData?.workspace?.id ?? 1) - 1) % root.workspacesShown
                    property var address: `0x${modelData.HyprlandToplevel.address}`
                    property bool atInitPosition: (initX == x && initY == y)
                    required property int index
                    required property var modelData
                    property var windowData: root.windowByAddress[address]
                    property int workspaceColIndex: _wsLocalIdx % OverviewConfig.columns
                    property int workspaceRowIndex: Math.floor(_wsLocalIdx / OverviewConfig.columns)

                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2
                    appClass: windowData?.class ?? "unknown"
                    availableWorkspaceHeight: root.workspaceAvailableHeight
                    availableWorkspaceWidth: root.workspaceAvailableWidth
                    overviewOpen: GlobalStates.overviewOpen
                    scale: root._previewScale(_srcMonitor)
                    sourceMonitorData: root._monitorSnapshot(_srcMonitor)
                    sourceMonitorId: _srcMonitorId
                    toplevel: modelData
                    widgetMonitorId: root.monitorId
                    windowAt: windowData?.at ?? [0, 0]
                    windowSize: windowData?.size ?? [100, 100]
                    windowTitle: windowData?.title ?? "Unknown"
                    xOffset: (root.workspaceImplicitWidth + root.workspaceSpacingPx) * workspaceColIndex
                    xwayland: windowData?.xwayland ?? false
                    yOffset: (root.workspaceImplicitHeight + root.workspaceSpacingPx) * workspaceRowIndex
                    z: atInitPosition ? (root.windowZ + index) : root.windowDraggingZ

                    Timer {
                        id: updateWindowPosition

                        interval: OverviewConfig.raceDelayMs
                        repeat: false
                        running: false

                        onTriggered: {
                            window.x = window.initX;
                            window.y = window.initY;
                        }
                    }
                    MouseArea {
                        id: dragArea

                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        anchors.fill: parent
                        drag.target: parent
                        hoverEnabled: true

                        onClicked: event => {
                            if (event.button === Qt.LeftButton) {
                                root.requestClose();
                                HyprlandManager.switchToWorkspace(windowData?.workspace?.id ?? root.activeWorkspaceId, event.modifiers);
                                Hyprland.dispatch(`focuswindow address:${window.address}`);
                                event.accepted = true;
                            } else if (event.button === Qt.MiddleButton) {
                                Hyprland.dispatch(`closewindow address:${window.address}`);
                                event.accepted = true;
                            }
                        }
                        onEntered: hovered = true
                        onExited: hovered = false
                        onPressed: mouse => {
                            root.draggingFromWorkspace = windowData?.workspace?.id ?? -1;
                            window.pressed = true;
                            window.Drag.active = true;
                            window.Drag.source = window;
                            window.Drag.hotSpot.x = mouse.x;
                            window.Drag.hotSpot.y = mouse.y;
                        }
                        onReleased: {
                            const targetWorkspace = root.draggingTargetWorkspace;
                            window.pressed = false;
                            window.Drag.active = false;
                            root.draggingFromWorkspace = -1;
                            if (targetWorkspace !== -1 && targetWorkspace !== windowData?.workspace?.id) {
                                HyprlandManager.moveToWorkspaceSilent(targetWorkspace, window.address ?? "");
                                updateWindowPosition.restart();
                            } else {
                                window.x = window.initX;
                                window.y = window.initY;
                            }
                        }

                        StyledToolTip {
                            alternativeVisibleCondition: dragArea.containsMouse && !window.Drag.active
                            extraVisibleCondition: false
                            text: `${window.windowTitle ?? "Unknown"}\n[${window.appClass ?? "unknown"}] ${window.xwayland ? "[XWayland] " : ""}`
                        }
                    }
                }
                model: ScriptModel {
                    values: {
                        const toplevels = ToplevelManager.toplevels.values;
                        const wba = root.windowByAddress;
                        const minWs = root.workspaceGroup * root.workspacesShown + 1;
                        const maxWs = (root.workspaceGroup + 1) * root.workspacesShown;

                        return toplevels.filter(toplevel => {
                            const address = `0x${toplevel.HyprlandToplevel.address}`;
                            const wsId = wba[address]?.workspace?.id ?? -1;
                            return wsId >= minWs && wsId <= maxWs;
                        }).sort((a, b) => {
                            const winA = wba[`0x${a.HyprlandToplevel.address}`];
                            const winB = wba[`0x${b.HyprlandToplevel.address}`];
                            if ((winA?.pinned ?? false) !== (winB?.pinned ?? false))
                                return (winA?.pinned ?? false) ? 1 : -1;
                            if ((winA?.floating ?? false) !== (winB?.floating ?? false))
                                return (winA?.floating ?? false) ? 1 : -1;
                            if (((winA?.fullscreen ?? 0) > 0) !== ((winB?.fullscreen ?? 0) > 0))
                                return (winA?.fullscreen ?? 0) > 0 ? 1 : -1;
                            const wsA = winA?.workspace?.id ?? 0;
                            const wsB = winB?.workspace?.id ?? 0;
                            if (wsA !== wsB)
                                return wsA - wsB;
                            return (winB?.focusHistoryID ?? 0) - (winA?.focusHistoryID ?? 0);
                        });
                    }
                }
            }
            Rectangle {
                id: focusedWorkspaceIndicator

                property int activeWorkspaceColIndex: (activeWorkspaceInGroup - 1) % OverviewConfig.columns
                property int activeWorkspaceInGroup: root.activeWorkspaceId - (root.workspaceGroup * root.workspacesShown)
                property int activeWorkspaceRowIndex: Math.floor((activeWorkspaceInGroup - 1) / OverviewConfig.columns)

                border.color: ColorConfig.accentAlt
                border.width: OverviewConfig.focusedIndicatorBorderWidth
                color: "transparent"
                height: root.workspaceImplicitHeight
                radius: OverviewConfig.screenRounding * root.overviewScale
                width: root.workspaceImplicitWidth
                x: (root.workspaceImplicitWidth + root.workspaceSpacingPx) * activeWorkspaceColIndex
                y: (root.workspaceImplicitHeight + root.workspaceSpacingPx) * activeWorkspaceRowIndex
                z: root.windowZ

                Behavior on x {
                    animation: OverviewConfig.animFastNumber.createObject(this)
                    enabled: root.initialized
                }
                Behavior on y {
                    animation: OverviewConfig.animFastNumber.createObject(this)
                    enabled: root.initialized
                }
            }
        }
    }
}
