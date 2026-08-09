pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property string cardId: ""
    readonly property var fileNames: ({
            "battery": "Battery",
            "cpuTemp": "CPUTemp",
            "gpuTemp": "GPUTemp",
            "media": "Media",
            "systemStats": "SystemStats",
            "volume": "Volume"
        })

    height: loader.item ? loader.item.height : 0
    width: parent ? parent.width : 0

    onCardIdChanged: {
        var name = root.fileNames[root.cardId];
        if (name)
            loader.setSource("../cards/" + name + "Card.qml");
    }

    Loader {
        id: loader

        width: parent.width
    }
}
