pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property var _defaultWidgets: ({
            left: [
                {
                    "id": "Power"
                },
                {
                    "id": "Workspace"
                },
                {
                    "id": "Dock"
                }
            ],
            center: [
                {
                    "id": "Clock",
                    "format": "ddd yyyy-MM-dd hh:mm:ss"
                }
            ],
            right: [
                {
                    "id": "Tray",
                    "startExpanded": false,
                    "arrowSide": "right",
                    "direction": "rtl"
                },
                {
                    "id": "SystemMonitor"
                },
                {
                    "id": "Network"
                },
                {
                    "id": "Bluetooth"
                },
                {
                    "id": "Volume"
                },
                {
                    "id": "Battery",
                    "hideIfNotDetected": true
                },
                {
                    "id": "ControlCenter"
                }
            ]
        })
    readonly property JsonAdapter adapter: JsonAdapter {
        property JsonObject bar: JsonObject {
            property bool autohideEnabled: false
        }
        property var barDisplays: ({})
        property var displays: ({})
        property JsonObject dock: JsonObject {
            property bool autohideEnabled: false
            property int marginBottom: 10
        }
        property var dockDisplays: ({})
        property JsonObject idle: JsonObject {
            property bool ambientEnabled: true
            property int ambientTimeoutSeconds: 150
            property bool enabled: true
            property bool screensaverEnabled: true
            property int screensaverTimeoutSeconds: 300
        }
        property var idleDisplays: ({})
        property JsonObject osd: JsonObject {
            property list<var> active: ["Sink", "Source"]
        }
        property var powerButtons: ([])
    }
    readonly property var barDisplays: adapter.barDisplays || {}
    readonly property string configDir: {
        var xdg = Quickshell.env("XDG_CONFIG_HOME");
        return (xdg || Quickshell.env("HOME") + "/.config") + "/keqing-shell/";
    }
    readonly property var displays: adapter.displays || {}
    readonly property var dockDisplays: adapter.dockDisplays || {}
    readonly property string filePath: configDir + "settings.json"
    property Timer firstRunTimer: Timer {
        interval: 250

        onTriggered: root.settingsFile.writeAdapter()
    }
    readonly property var idleDisplays: adapter.idleDisplays || {}
    property bool loaded: false
    readonly property var powerButtons: adapter.powerButtons || []
    property Timer saveTimer: Timer {
        interval: 600

        onTriggered: root.settingsFile.writeAdapter()
    }
    property FileView settingsFile: FileView {
        adapter: root.adapter
        path: root.filePath
        printErrors: false
        watchChanges: true

        onLoadFailed: error => {
            var msg = error.toString();
            if (msg.includes("No such file") || msg.includes("ENOENT") || error === 2) {
                Quickshell.execDetached(["mkdir", "-p", root.configDir]);
                firstRunTimer.start();
            }
            root.loaded = true;
        }
        onLoaded: root.loaded = true
    }
    function barValue(screenName, key) {
        if (!screenName || screenName === "default")
            return adapter.bar[key];
        var entry = root.barDisplays[screenName];
        if (entry && entry._enabled !== false && entry[key] !== undefined)
            return entry[key];
        return adapter.bar[key];
    }
    function barValueForScreen(screen, key) {
        if (!screen)
            return adapter.bar[key];
        var entry = root.barDisplays[screen.name] !== undefined ? root.barDisplays[screen.name] : root.barDisplays[screen.model];
        if (entry && entry._enabled !== false && entry[key] !== undefined)
            return entry[key];
        return adapter.bar[key];
    }
    function displayValue(screenName, key) {
        if (!screenName || screenName === "default")
            return (root.displays["default"] || {})[key] !== false;
        var entry = root.displays[screenName];
        if (entry && entry._enabled !== false && entry[key] !== undefined)
            return entry[key] !== false;
        return (root.displays["default"] || {})[key] !== false;
    }
    function dockValue(screenName, key) {
        if (!screenName || screenName === "default")
            return adapter.dock[key];
        var entry = root.dockDisplays[screenName];
        if (entry && entry._enabled !== false && entry[key] !== undefined)
            return entry[key];
        return adapter.dock[key];
    }
    function dockValueForScreen(screen, key) {
        if (!screen)
            return adapter.dock[key];
        var entry = root.dockDisplays[screen.name] !== undefined ? root.dockDisplays[screen.name] : root.dockDisplays[screen.model];
        if (entry && entry._enabled !== false && entry[key] !== undefined)
            return entry[key];
        return adapter.dock[key];
    }
    function ensureBarScreen(screenName) {
        var all = JSON.parse(JSON.stringify(root.barDisplays));
        if (!all[screenName])
            all[screenName] = {};
        return all;
    }
    function ensureDisplayScreen(screenName) {
        var all = JSON.parse(JSON.stringify(root.displays));
        if (!all[screenName]) {
            var def = all["default"] || {};
            all[screenName] = Object.assign({}, def);
        }
        return all;
    }
    function ensureDockScreen(screenName) {
        var all = JSON.parse(JSON.stringify(root.dockDisplays));
        if (!all[screenName])
            all[screenName] = {};
        return all;
    }
    function ensureIdleScreen(screenName) {
        var all = JSON.parse(JSON.stringify(root.idleDisplays));
        if (!all[screenName])
            all[screenName] = {};
        return all;
    }
    function idleValue(screenName, key) {
        if (!screenName || screenName === "default")
            return adapter.idle[key];
        var entry = root.idleDisplays[screenName];
        if (entry && entry._enabled !== false && entry[key] !== undefined)
            return entry[key];
        return adapter.idle[key];
    }
    function idleValueForScreen(screen, key) {
        if (!screen)
            return adapter.idle[key];
        var entry = root.idleDisplays[screen.name] !== undefined ? root.idleDisplays[screen.name] : root.idleDisplays[screen.model];
        if (entry && entry._enabled !== false && entry[key] !== undefined)
            return entry[key];
        return adapter.idle[key];
    }
    function save() {
        saveTimer.restart();
    }
    function setBarOverrideEnabled(screenName, enabled) {
        if (!root.barDisplays[screenName] && !enabled)
            return;
        var all = ensureBarScreen(screenName);
        all[screenName]._enabled = enabled;
        adapter.barDisplays = all;
        save();
    }
    function setBarValue(screenName, key, value) {
        if (!screenName || screenName === "default") {
            adapter.bar[key] = value;
            save();
            return;
        }
        var all = ensureBarScreen(screenName);
        all[screenName][key] = value;
        adapter.barDisplays = all;
        save();
    }
    function setDisplayOverrideEnabled(screenName, enabled) {
        if (!root.displays[screenName] && !enabled)
            return;
        var all = ensureDisplayScreen(screenName);
        all[screenName]._enabled = enabled;
        adapter.displays = all;
        save();
    }
    function setDisplayValue(screenName, key, value) {
        var name = (!screenName || screenName === "default") ? "default" : screenName;
        var all = ensureDisplayScreen(name);
        all[name][key] = value;
        adapter.displays = all;
        save();
    }
    function setDisplays(obj) {
        adapter.displays = obj;
        save();
    }
    function setDockOverrideEnabled(screenName, enabled) {
        if (!root.dockDisplays[screenName] && !enabled)
            return;
        var all = ensureDockScreen(screenName);
        all[screenName]._enabled = enabled;
        adapter.dockDisplays = all;
        save();
    }
    function setDockValue(screenName, key, value) {
        if (!screenName || screenName === "default") {
            adapter.dock[key] = value;
            save();
            return;
        }
        var all = ensureDockScreen(screenName);
        all[screenName][key] = value;
        adapter.dockDisplays = all;
        save();
    }
    function setIdleEnabled(enabled) {
        IdleService.reset();
        adapter.idle.enabled = enabled;
        save();
    }
    function setIdleOverrideEnabled(screenName, enabled) {
        if (!root.idleDisplays[screenName] && !enabled)
            return;
        IdleService.reset(screenName);
        var all = ensureIdleScreen(screenName);
        all[screenName]._enabled = enabled;
        adapter.idleDisplays = all;
        save();
    }
    function setIdleValue(screenName, key, value) {
        if (!screenName || screenName === "default") {
            IdleService.reset(screenName);
            adapter.idle[key] = value;
            save();
            return;
        }
        IdleService.reset(screenName);
        var all = ensureIdleScreen(screenName);
        all[screenName][key] = value;
        adapter.idleDisplays = all;
        save();
    }
    function setOsd(arr) {
        adapter.osd.active = arr;
        save();
    }
    function setPowerButtons(arr) {
        adapter.powerButtons = arr;
        save();
    }
}
