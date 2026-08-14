pragma ComponentBehavior: Bound

import QtQuick

import qs.config

Row {
    id: root

    property var position: ""
    property var screen: null
    property var widgets: []

    function setRegion() {
        anchors.verticalCenter = parent.verticalCenter;
        if (position === "left")
            anchors.left = parent.left;
        else if (position === "center")
            anchors.horizontalCenter = parent.horizontalCenter;
        else if (position === "right")
            anchors.right = parent.right;
    }

    spacing: BarConfig.widgetSpacing

    Component.onCompleted: setRegion()

    Repeater {
        model: root.widgets

        delegate: WidgetLoader {
            required property var modelData

            screen: root.screen
            widgetConfig: modelData
        }
    }
}
