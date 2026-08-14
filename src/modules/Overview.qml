pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules
import qs.overview.layout
import qs.overview.service

ModuleLoader {
    id: root

    module: "overview"

    sourceComp: Component {
        Scope {
            id: panel

            property alias controller: controller

            signal closeRequested

            Component.onCompleted: controller.open()

            Item {
                id: controller

                function close() {
                    GlobalStates.overviewOpen = false;
                }
                function open() {
                    GlobalStates.overviewOpen = true;
                }
            }
            OverviewWindow {
                onClosed: panel.closeRequested()
                onDismissRequested: panel.controller.close()
            }
        }
    }

    IpcHandler {
        function toggle() {
            root.toggle();
        }

        target: "overview"
    }
}
