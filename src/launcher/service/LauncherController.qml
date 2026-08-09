pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.launcher
import qs.launcher.service

Item {
    id: root

    property string baseMode: LauncherConfig.modeDrun
    property var browseRef: null
    property string effectiveQuery: ""
    property bool isOpen: false
    property var mode: null
    property string query: ""
    property var resultsModel: directoryBrowser.active ? directoryBrowser.results : filtered.values
    property string searchRoot: Quickshell.env("HOME")
    readonly property bool subMenuOpen: directoryBrowser.active

    signal closeRequested

    function close(resetInput) {
        directoryBrowser.close();
        if (resetInput === undefined || resetInput) {
            if (root.browseRef && root.browseRef.input)
                root.browseRef.input.text = "";
        }

        root.resetSelection();
        root.effectiveQuery = "";
        root.mode = null;
        root.isOpen = false;
        root.closeRequested();
    }
    function currentModelData() {
        var current = (root.browseRef && root.browseRef.list) ? root.browseRef.list.currentItem : null;
        return (current && current.modelData) ? current.modelData : null;
    }
    function detectModeAndQuery(raw) {
        const src = String(raw || "");
        const t = root.trimLeft(src);
        if (t === "")
            return {
                mode: root.baseMode,
                query: ""
            };
        const map = LauncherConfig.searchPrefixes;
        for (var k in map) {
            const expr = String(k || "");
            if (expr === "")
                continue;
            if (!t.startsWith(expr))
                continue;
            if (/^[a-zA-Z0-9]+$/.test(expr)) {
                const next = t.charAt(expr.length);
                if (next !== "" && next !== undefined && !/\s/.test(next))
                    continue;
            }

            const rest = root.trimLeft(t.slice(expr.length));
            return {
                mode: root.normalizeMode(String(map[k])),
                query: rest
            };
        }

        return {
            mode: root.baseMode,
            query: src
        };
    }
    function focusInput() {
        if (root.browseRef && root.browseRef.input)
            root.browseRef.input.forceActiveFocus();
    }
    function goBack() {
        if (directoryBrowser.active) {
            directoryBrowser.goBack();
        } else {
            root.close();
        }
    }
    function launch(modelData) {
        const entry = modelData || root.currentModelData();

        if (directoryBrowser.handleEntry(entry)) {
            return;
        }

        const mode = root.mode || LauncherConfig.modeDrun;
        if (mode === LauncherConfig.modeDrun && entry && entry.path && String(entry.path).length > 0 && !entry._dirMenuAction) {
            if (entry.isDir) {
                directoryBrowser.openDirectory(entry.path);
                return;
            } else {
                directoryBrowser.openFileActions(entry);
                return;
            }
        }

        if (launchAction && launchAction.launch) {
            launchAction.launch(modelData);
            root.close();
        }
    }
    function normalizeMode(m) {
        const s = (m === undefined || m === null) ? "" : String(m);
        if (LauncherConfig.modeIcons[s] !== undefined)
            return s;
        return LauncherConfig.modeDrun;
    }
    function open(global) {
        directoryBrowser.close();

        root.searchRoot = global ? "/" : Quickshell.env("HOME");
        root.isOpen = true;
        root.baseMode = LauncherConfig.modeDrun;
        root.mode = LauncherConfig.modeDrun;
        root.updateAutoMode();
        root.focusInput();
        root.resetSelection();
    }
    function resetSelection() {
        if (root.browseRef && root.browseRef.list) {
            var len = root.browseRef.resultsCount;
            root.browseRef.list.currentIndex = (len > 0) ? 0 : -1;
        }
    }
    function trimLeft(s) {
        return String(s || "").replace(/^\s+/, "");
    }
    function updateAutoMode() {
        const detected = root.detectModeAndQuery(root.query);
        root.effectiveQuery = detected.query;
        if (root.mode !== detected.mode)
            root.mode = detected.mode;
    }

    onModeChanged: {
        if (directoryBrowser.active)
            directoryBrowser.close();
        if (root.mode === null || root.mode === undefined) {
            return;
        }

        const current = String(root.mode);
        const normalized = root.normalizeMode(current);
        if (normalized !== current)
            root.mode = normalized;
    }
    onQueryChanged: {
        if (directoryBrowser.active)
            directoryBrowser.close();
        root.updateAutoMode();
    }

    ScriptModel {
        id: filtered

        values: {
            if (root.mode === LauncherConfig.modeDrun)
                return provider.results;
            return [];
        }
    }
    Provider {
        id: provider

        enabled: root.mode === LauncherConfig.modeDrun
        query: root.effectiveQuery
        searchRoot: root.searchRoot
    }
    SubMenu {
        id: directoryBrowser

        onRequestSelectionReset: root.resetSelection()
    }
    LaunchAction {
        id: launchAction

        browseRef: root.browseRef
        launcherRef: root
    }
}
