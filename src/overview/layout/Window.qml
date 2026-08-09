pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

import qs.overview
import qs.config

Item {
    id: root

    readonly property real _availH: Math.max(availableWorkspaceHeight, 1)
    readonly property real _availW: Math.max(availableWorkspaceWidth, 1)
    readonly property real _baseH: Math.min(_rawH, _availH)
    readonly property real _baseW: Math.min(_rawW, _availW)
    readonly property real _baseX: _clamp(_rawX, 0, Math.max(0, _availW - _baseW))
    readonly property real _baseY: _clamp(_rawY, 0, Math.max(0, _availH - _baseH))
    readonly property real _rawH: Math.max(1, (root.windowSize?.[1] ?? 100) * root.scale)
    readonly property real _rawW: Math.max(1, (root.windowSize?.[0] ?? 100) * root.scale)
    readonly property real _rawX: Math.max(((root.windowAt?.[0] ?? 0) - (root.sourceMonitorData?.x ?? 0) - (root.sourceMonitorData?.reserved?.[0] ?? 0)) * root.scale, 0)
    readonly property real _rawY: Math.max(((root.windowAt?.[1] ?? 0) - (root.sourceMonitorData?.y ?? 0) - (root.sourceMonitorData?.reserved?.[1] ?? 0)) * root.scale, 0)
    readonly property real _x1: xOffset + _baseX
    readonly property real _x2: _x1 + Math.max(1, _baseW)
    readonly property real _y1: yOffset + _baseY
    readonly property real _y2: _y1 + Math.max(1, _baseH)
    property string appClass: ""
    property var availableWorkspaceHeight
    property var availableWorkspaceWidth
    property var entry: DesktopEntries.heuristicLookup(root.appClass)
    property bool hovered: false
    property string iconName: entry?.icon || root.appClass || "application-x-executable"
    property string iconPath: Quickshell.iconPath(iconName) || ""
    property real initX: Math.round(_x1)
    property real initY: Math.round(_y1)
    property bool initialized: false
    property bool overviewOpen: false
    property bool pressed: false
    property bool restrictToWorkspace: true
    property var scale
    property var sourceMonitorData
    property int sourceMonitorId: -1
    property var toplevel
    property int widgetMonitorId: 0
    property var windowAt
    property var windowSize: [100, 100]
    property string windowTitle: ""
    property real xOffset: 0
    property bool xwayland: false
    property real yOffset: 0

    function _clamp(v, lo, hi) {
        if (hi < lo)
            return lo;
        return Math.max(lo, Math.min(v, hi));
    }

    clip: true
    height: Math.max(1, Math.round(_y2) - Math.round(_y1))
    opacity: root.sourceMonitorId == widgetMonitorId ? 1 : OverviewConfig.otherMonitorOpacity
    width: Math.max(1, Math.round(_x2) - Math.round(_x1))
    x: initX
    y: initY

    Behavior on height {
        animation: OverviewConfig.animFastNumber.createObject(this)
        enabled: root.initialized
    }
    Behavior on width {
        animation: OverviewConfig.animFastNumber.createObject(this)
        enabled: root.initialized
    }
    Behavior on x {
        animation: OverviewConfig.animFastNumber.createObject(this)
        enabled: root.initialized
    }
    Behavior on y {
        animation: OverviewConfig.animFastNumber.createObject(this)
        enabled: root.initialized
    }

    Component.onCompleted: Qt.callLater(() => root.initialized = true)

    Rectangle {
        anchors.fill: parent
        color: ColorConfig.fieldBg
        radius: OverviewConfig.windowRounding * root.scale
        visible: root.sourceMonitorId === root.widgetMonitorId
    }
    ScreencopyView {
        id: windowPreview

        readonly property real srcAspect: {
            const w = root.windowSize?.[0] ?? 0;
            const h = root.windowSize?.[1] ?? 0;
            return (w > 0 && h > 0) ? (w / h) : 1;
        }

        anchors.centerIn: parent
        captureSource: root.overviewOpen ? root.toplevel : null
        height: Math.min(parent.height, parent.width / srcAspect)
        layer.enabled: true
        layer.smooth: true
        live: true
        width: Math.min(parent.width, parent.height * srcAspect)

        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: previewMask
            maskSpreadAtMin: 1.0
            maskThresholdMin: 0.5
        }
    }
    Rectangle {
        anchors.fill: parent
        border.color: ColorConfig.accent
        border.width: OverviewConfig.windowPreviewBorderWidth
        color: pressed ? ColorConfig.accentAlpha20 : hovered ? ColorConfig.textAlpha08 : "transparent"
        radius: OverviewConfig.windowRounding * root.scale
    }
    Image {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        anchors.right: parent.right
        anchors.rightMargin: 6
        height: Math.min(parent.width, parent.height) * OverviewConfig.iconToWindowRatio / (root.sourceMonitorData?.scale ?? 1)
        source: root.iconPath
        sourceSize: Qt.size(height, height)
        width: height
    }
    Item {
        id: previewMask

        anchors.centerIn: parent
        height: windowPreview.height
        layer.enabled: true
        layer.smooth: true
        visible: false
        width: windowPreview.width

        Rectangle {
            anchors.centerIn: parent
            height: root.height
            radius: OverviewConfig.windowRounding * root.scale
            width: root.width
        }
    }
}
