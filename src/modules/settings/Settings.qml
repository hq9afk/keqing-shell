pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.service
import qs.modules.core
import qs.modules.settings.layout

ModuleLoader {
    id: root

    module: "settings"

    sourceComp: Component {
        Scope {
            id: panel

            property alias controller: ctrl

            signal closeRequested

            QtObject {
                id: ctrl

                function close() {
                    settingsWindow.close();
                }
                function open() {
                    settingsWindow.open();
                }
            }
            SettingsWindow {
                id: settingsWindow

                onClosed: panel.closeRequested()
            }
        }
    }

    IpcHandler {
        function toggle() {
            root.toggle();
        }

        target: "settings"
    }
}
