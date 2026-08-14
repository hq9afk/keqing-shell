pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property var screen: null
    property var widgetConfig: ({})

    height: implicitHeight
    implicitHeight: loader.implicitHeight
    implicitWidth: loader.implicitWidth
    width: implicitWidth

    Loader {
        id: loader

        Component.onCompleted: {
            var widgetId = root.widgetConfig.id || "";
            if (widgetId)
                setSource("../widgets/" + widgetId + "Widget.qml", {
                    "screen": root.screen
                });
        }
        onItemChanged: {
            if (item && "config" in item)
                item.config = Qt.binding(() => root.widgetConfig);
        }
    }
}
