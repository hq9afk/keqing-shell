pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.service
import qs.overview

Item {
    id: root

    property var activeWorkspace: null
    property var addresses: []
    readonly property bool hasMultiWindowWorkspace: {
        var counts = {};
        for (var i = 0; i < root.windowList.length; ++i) {
            var wsId = root.windowList[i]?.workspace?.id;
            if (wsId === undefined)
                continue;
            counts[wsId] = (counts[wsId] || 0) + 1;
            if (counts[wsId] > 1)
                return true;
        }
        return false;
    }
    property var layers: ({})
    property var monitors: []
    readonly property string tilingScript: "hyprtile"
    property var windowByAddress: ({})
    property var windowList: []
    property var workspaceById: ({})
    property var workspaceIds: []
    property var workspaces: []

    function _exec(cmd) {
        Quickshell.execDetached(["bash", "-c", cmd]);
    }
    function clearWorkspace(modifiers) {
        root._exec(`${root.tilingScript} cw ${(modifiers & Qt.ShiftModifier) ? "a" : ""}`);
    }
    function moveToWorkspaceSilent(workspaceId, windowAddress) {
        if (!windowAddress) {
            return;
        }
        root._exec(`${root.tilingScript} mw q ${workspaceId} ${windowAddress}`);
    }
    function switchToWorkspace(workspaceId, modifiers) {
        if (modifiers & Qt.ShiftModifier)
            root._exec(`${root.tilingScript} sw ${workspaceId}`);
        else if (modifiers & Qt.AltModifier)
            root._exec(`${root.tilingScript} mi ${workspaceId}`);
        else
            root._exec(`${root.tilingScript} fw ${workspaceId}`);
    }
    function updateAll() {
        updateWindowList();
        updateMonitors();
        updateLayers();
        updateWorkspaces();
    }
    function updateLayers() {
        getLayers.running = true;
    }
    function updateMonitors() {
        getMonitors.running = true;
    }
    function updateWindowList() {
        getClients.running = true;
    }
    function updateWorkspaces() {
        getWorkspaces.running = true;
        getActiveWorkspace.running = true;
    }

    Component.onCompleted: {
        updateAll();
    }

    Timer {
        id: updateDebounce

        interval: 30
        repeat: false

        onTriggered: root.updateAll()
    }
    Connections {
        function onChanged() {
            updateDebounce.restart();
        }

        target: HyprlandService
    }
    Timer {
        id: windowPollTimer

        interval: 500
        repeat: true
        running: root.hasMultiWindowWorkspace

        onTriggered: root.updateWindowList()
    }
    Process {
        id: getClients

        command: ["hyprctl", "clients", "-j"]

        stdout: StdioCollector {
            id: clientsCollector

            onStreamFinished: {
                root.windowList = JSON.parse(clientsCollector.text);
                let tempWinByAddress = {};
                for (var i = 0; i < root.windowList.length; ++i) {
                    var win = root.windowList[i];
                    tempWinByAddress[win.address] = win;
                }
                root.windowByAddress = tempWinByAddress;
                root.addresses = root.windowList.map(win => win.address);
            }
        }
    }
    Process {
        id: getMonitors

        command: ["hyprctl", "monitors", "-j"]

        stdout: StdioCollector {
            id: monitorsCollector

            onStreamFinished: {
                root.monitors = JSON.parse(monitorsCollector.text);
            }
        }
    }
    Process {
        id: getLayers

        command: ["hyprctl", "layers", "-j"]

        stdout: StdioCollector {
            id: layersCollector

            onStreamFinished: {
                root.layers = JSON.parse(layersCollector.text);
            }
        }
    }
    Process {
        id: getWorkspaces

        command: ["hyprctl", "workspaces", "-j"]

        stdout: StdioCollector {
            id: workspacesCollector

            onStreamFinished: {
                root.workspaces = JSON.parse(workspacesCollector.text);
                let tempWorkspaceById = {};
                for (var i = 0; i < root.workspaces.length; ++i) {
                    var ws = root.workspaces[i];
                    tempWorkspaceById[ws.id] = ws;
                }
                root.workspaceById = tempWorkspaceById;
                root.workspaceIds = root.workspaces.map(ws => ws.id);
            }
        }
    }
    Process {
        id: getActiveWorkspace

        command: ["hyprctl", "activeworkspace", "-j"]

        stdout: StdioCollector {
            id: activeWorkspaceCollector

            onStreamFinished: {
                root.activeWorkspace = JSON.parse(activeWorkspaceCollector.text);
            }
        }
    }
}
