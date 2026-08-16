import QtQuick
import Quickshell
import Quickshell.Io

import qs.launcher
import qs.modules

ModuleLoader {
    id: launcherRoot

    module: "launcher"

    sourceComp: Component {
        Panel {}
    }

    IpcHandler {
        function toggle() {
            launcherRoot.toggle(false);
        }
        function toggleGlobal() {
            launcherRoot.toggle(true);
        }

        target: "launcher"
    }
}
