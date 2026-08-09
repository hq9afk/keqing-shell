pragma ComponentBehavior: Bound

import QtQuick

import qs.bar
import qs.bar.service
import qs.core
import qs.config

Item {
    id: root

    property bool _panelOpenLinger: false
    readonly property bool baseShowLabel: hovered || isPanelOpen || _panelOpenLinger
    property color borderColor: ColorConfig.accent
    property alias capsuleVisible: capsule.visible
    property var config: ({})
    readonly property bool hovered: hoverHandler.hovered
    property string iconGlyph: ""
    readonly property bool isPanelOpen: panelName !== "" && (PanelService.openedPanel?.objectName === panelName + "-" + (screen?.name ?? "") || (moduleActive && moduleOpenedHere))
    property string labelText: ""
    property real labelW: showLabel ? Math.round(labelItem.implicitWidth) : 0
    readonly property bool moduleActive: panelName !== "" && ModuleStates.isOpen(panelName)
    property bool moduleOpenedHere: false
    property string panelName: ""
    property var screen: null
    property bool showLabel: false

    implicitHeight: BarConfig.capsuleHeight
    implicitWidth: BarConfig.capsuleHeight + (labelW > 0.5 ? labelW + Math.round((BarConfig.capsuleHeight - iconItem.width) / 2) : 0)

    Behavior on labelW {
        NumberAnimation {
            duration: BarConfig.capsuleLabelAnimMs
            easing.type: Easing.OutCubic
        }
    }

    onIsPanelOpenChanged: {
        if (!isPanelOpen && panelName !== "") {
            _panelOpenLinger = true;
            panelLingerTimer.restart();
        } else {
            panelLingerTimer.stop();
            _panelOpenLinger = false;
        }
    }
    onModuleActiveChanged: {
        moduleOpenedHere = moduleActive && hovered;
        if (panelName !== "")
            ModuleStates.setOpenedFromBar(panelName, moduleOpenedHere ? (screen?.name ?? "") : "");
    }

    Timer {
        id: panelLingerTimer

        interval: BarConfig.capsuleLingerMs

        onTriggered: root._panelOpenLinger = false
    }
    HoverHandler {
        id: hoverHandler
    }
    Rectangle {
        id: capsule

        anchors.fill: parent
        border.color: root.borderColor
        border.width: BarConfig.capsuleBorderWidth
        clip: true
        color: ColorConfig.overlay
        radius: BarConfig.capsuleRadius
    }
    Item {
        id: iconSection

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.top: parent.top
        width: BarConfig.capsuleHeight

        Text {
            id: iconItem

            color: ColorConfig.text
            font.family: IconConfig.fontFamily
            font.pixelSize: BarConfig.iconSize
            text: root.iconGlyph
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2 + (height - contentHeight) / 2)
        }
    }
    Text {
        id: labelItem

        anchors.left: iconSection.right
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        color: ColorConfig.text
        font.family: FontConfig.fontFamily
        font.pixelSize: FontConfig.fontBody
        opacity: root.showLabel ? BarConfig.capsuleLabelVisibleOpacity : BarConfig.capsuleLabelHiddenOpacity
        text: root.labelText
        width: root.labelW

        Behavior on opacity {
            NumberAnimation {
                duration: BarConfig.capsuleLabelAnimMs
                easing.type: Easing.OutCubic
            }
        }
    }
}
