pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property string module: ""
    required property Component sourceComp

    function toggle(arg) {
        if (loader.active) {
            if (loader.item && loader.item.controller) {
                loader.item.controller.close();
            }
        } else {
            root._pendingArg = arg;
            loader.active = true;
        }
    }

    property var _pendingArg: undefined

    Loader {
        id: loader

        active: false
        asynchronous: false
        sourceComponent: root.sourceComp

        onActiveChanged: {
            if (!active)
                ModuleStates.setOpen(root.module, false);
        }
        onLoaded: {
            item.controller.open(root._pendingArg);
            ModuleStates.setOpen(root.module, true);
        }

        Connections {
            function onCloseRequested() {
                Qt.callLater(function () {
                    loader.active = false;
                });
            }

            ignoreUnknownSignals: true
            target: loader.item
        }
    }
}
