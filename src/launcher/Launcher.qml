pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.core
import qs.launcher
import qs.launcher.layout
import qs.launcher.service

ModuleLoader {
    id: root

    module: "launcher"

    sourceComp: Component {
        Scope {
            id: panel

            property alias controller: controller

            signal closeRequested

            LauncherController {
                id: controller

                browseRef: window.browseRef

                onCloseRequested: panel.closeRequested()
            }
            LauncherWindow {
                id: window

                launcherRef: controller
                mode: controller.mode || LauncherConfig.modeDrun
                resultsModel: controller.resultsModel
                visible: controller.isOpen

                onDismissRequested: controller.goBack()
                onEntryActivated: controller.launch(modelData)
                onQueryEdited: text => controller.query = text
            }
        }
    }

    IpcHandler {
        function toggle() {
            root.toggle(false);
        }
        function toggleGlobal() {
            root.toggle(true);
        }

        target: "launcher"
    }
}
