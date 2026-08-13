pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

import qs.components
import qs.config
import qs.core
import qs.launcher
import qs.service

ModuleLoader {
    id: launcherRoot

    module: "launcher"

    sourceComp: Component {
        Scope {
            id: panel

            property alias controller: controller

            signal closeRequested

            Item {
                id: controller

                property string baseMode: LauncherConfig.modeDrun
                property var browseRef: window.browseRef
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
                        if (controller.browseRef && controller.browseRef.input)
                            controller.browseRef.input.text = "";
                    }

                    controller.resetSelection();
                    controller.effectiveQuery = "";
                    controller.mode = null;
                    controller.isOpen = false;
                    controller.closeRequested();
                }
                function currentModelData() {
                    var current = (controller.browseRef && controller.browseRef.list) ? controller.browseRef.list.currentItem : null;
                    return (current && current.modelData) ? current.modelData : null;
                }
                function detectModeAndQuery(raw) {
                    const src = String(raw || "");
                    const t = controller.trimLeft(src);
                    if (t === "")
                        return {
                            mode: controller.baseMode,
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

                        const rest = controller.trimLeft(t.slice(expr.length));
                        return {
                            mode: controller.normalizeMode(String(map[k])),
                            query: rest
                        };
                    }

                    return {
                        mode: controller.baseMode,
                        query: src
                    };
                }
                function focusInput() {
                    if (controller.browseRef && controller.browseRef.input)
                        controller.browseRef.input.forceActiveFocus();
                }
                function goBack() {
                    if (directoryBrowser.active) {
                        directoryBrowser.goBack();
                    } else {
                        controller.close();
                    }
                }
                function launch(modelData) {
                    const entry = modelData || controller.currentModelData();

                    if (directoryBrowser.handleEntry(entry)) {
                        return;
                    }

                    const mode = controller.mode || LauncherConfig.modeDrun;
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
                        controller.close();
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

                    controller.searchRoot = global ? "/" : Quickshell.env("HOME");
                    controller.isOpen = true;
                    controller.baseMode = LauncherConfig.modeDrun;
                    controller.mode = LauncherConfig.modeDrun;
                    controller.updateAutoMode();
                    controller.focusInput();
                    controller.resetSelection();
                }
                function resetSelection() {
                    if (controller.browseRef && controller.browseRef.list) {
                        var len = controller.browseRef.resultsCount;
                        controller.browseRef.list.currentIndex = (len > 0) ? 0 : -1;
                    }
                }
                function trimLeft(s) {
                    return String(s || "").replace(/^\s+/, "");
                }
                function updateAutoMode() {
                    const detected = controller.detectModeAndQuery(controller.query);
                    controller.effectiveQuery = detected.query;
                    if (controller.mode !== detected.mode)
                        controller.mode = detected.mode;
                }

                onCloseRequested: panel.closeRequested()
                onModeChanged: {
                    if (directoryBrowser.active)
                        directoryBrowser.close();
                    if (controller.mode === null || controller.mode === undefined) {
                        return;
                    }

                    const current = String(controller.mode);
                    const normalized = controller.normalizeMode(current);
                    if (normalized !== current)
                        controller.mode = normalized;
                }
                onQueryChanged: {
                    if (directoryBrowser.active)
                        directoryBrowser.close();
                    controller.updateAutoMode();
                }

                ScriptModel {
                    id: filtered

                    values: {
                        if (controller.mode === LauncherConfig.modeDrun)
                            return provider.results;
                        return [];
                    }
                }
                Item {
                    id: provider

                    property bool filesEnabled: true
                    property int maxResults: 50
                    property string pendingQuery: ""
                    property string query: controller.effectiveQuery
                    property var results: []
                    property string runningQuery: ""
                    property string searchRoot: controller.searchRoot

                    function computeAppScore(entry, qLower) {
                        const name = (entry && entry.name) ? String(entry.name).toLowerCase() : "";
                        if (name === "" || qLower === "")
                            return -1;

                        const idx = name.indexOf(qLower);
                        if (idx < 0)
                            return -1;

                        let score = (idx === 0) ? 1000 : 500;
                        score -= Math.min(idx, 200);
                        score -= Math.min(name.length, 200) / 10;
                        return score;
                    }
                    function recompute() {
                        const q = (provider.runningQuery || "").trim();
                        const qLower = q.toLowerCase();

                        if (!provider.enabled || qLower === "") {
                            provider.results = [];
                            return;
                        }

                        const decorated = [];

                        const appRes = apps.results || [];
                        for (let i = 0; i < appRes.length; i += 1) {
                            const it = appRes[i];
                            const visits = VisitStore.getCount(it);
                            decorated.push({
                                item: it,
                                kind: "app",
                                isDir: false,
                                score: provider.computeAppScore(it, qLower),
                                visits: visits,
                                nameLower: (it && it.name) ? String(it.name).toLowerCase() : ""
                            });
                        }

                        const fileRes = files.results || [];
                        for (let j = 0; j < fileRes.length; j += 1) {
                            const it2 = fileRes[j];
                            const score2 = (it2 && it2._score !== undefined) ? it2._score : provider.computeAppScore(it2, qLower);
                            const visits2 = VisitStore.getCount(it2);
                            decorated.push({
                                item: it2,
                                kind: "file",
                                isDir: !!(it2 && it2.isDir),
                                score: score2,
                                visits: visits2,
                                nameLower: (it2 && it2.name) ? String(it2.name).toLowerCase() : ""
                            });
                        }

                        decorated.sort(function (a, b) {
                            const aRank = (a.kind === "app") ? 0 : (a.isDir ? 1 : 2);
                            const bRank = (b.kind === "app") ? 0 : (b.isDir ? 1 : 2);
                            if (aRank !== bRank)
                                return aRank - bRank;

                            const av = (a.visits !== undefined) ? a.visits : 0;
                            const bv = (b.visits !== undefined) ? b.visits : 0;
                            if (av !== bv)
                                return bv - av;

                            const as = (a.score !== undefined) ? a.score : 0;
                            const bs = (b.score !== undefined) ? b.score : 0;
                            if (as !== bs)
                                return bs - as;

                            if (a.nameLower < b.nameLower)
                                return -1;
                            if (a.nameLower > b.nameLower)
                                return 1;
                            return 0;
                        });

                        provider.results = decorated.slice(0, provider.maxResults).map(d => d.item);
                    }
                    function scheduleQueryUpdate() {
                        if (!provider.enabled) {
                            provider.pendingQuery = "";
                            provider.runningQuery = "";
                            provider.results = [];
                            return;
                        }

                        const q = (provider.query || "");
                        if (q.trim() === "") {
                            provider.pendingQuery = "";
                            provider.runningQuery = "";
                            provider.results = [];
                            return;
                        }

                        provider.pendingQuery = q;
                        queryDebounce.restart();
                    }

                    enabled: controller.mode === LauncherConfig.modeDrun

                    onEnabledChanged: scheduleQueryUpdate()
                    onFilesEnabledChanged: recompute()
                    onMaxResultsChanged: recompute()
                    onQueryChanged: scheduleQueryUpdate()

                    Connections {
                        function onChanged() {
                            provider.recompute();
                        }

                        target: VisitStore
                    }
                    Timer {
                        id: queryDebounce

                        interval: 120
                        repeat: false

                        onTriggered: {
                            if (!provider.enabled) {
                                provider.runningQuery = "";
                                provider.results = [];
                                return;
                            }

                            const q = (provider.pendingQuery || "").trim();
                            provider.runningQuery = q;
                            provider.recompute();
                        }
                    }
                    Item {
                        id: apps

                        property string query: provider.runningQuery
                        property var results: []

                        function compute() {
                            const q = (apps.query || "").trim().toLowerCase();
                            if (q === "") {
                                apps.results = [];
                                return;
                            }

                            const allEntries = [...DesktopEntries.applications.values];
                            let res = allEntries.filter(d => d.name && d.name.toLowerCase().includes(q));

                            res.sort(function (a, b) {
                                const an = (a.name || "").toLowerCase();
                                const bn = (b.name || "").toLowerCase();

                                const aStarts = an.startsWith(q);
                                const bStarts = bn.startsWith(q);
                                if (aStarts && !bStarts)
                                    return -1;
                                if (bStarts && !aStarts)
                                    return 1;

                                if (an < bn)
                                    return -1;
                                if (an > bn)
                                    return 1;
                                return 0;
                            });

                            apps.results = res;
                        }

                        Component.onCompleted: compute()
                        onQueryChanged: compute()
                        onResultsChanged: provider.recompute()
                    }
                    Item {
                        id: files

                        property int debounceInterval: 0
                        property bool dirsDone: false
                        property var dirsResults: []
                        property bool filesDone: false
                        property var filesResults: []
                        property int maxResults: provider.maxResults
                        property string pendingQuery: ""
                        property string query: provider.runningQuery
                        property var results: []
                        property string runningPattern: ""
                        property string runningQuery: ""
                        property string searchRoot: provider.searchRoot

                        function basename(p) {
                            if (!p)
                                return "";
                            const s = files.normalizePath(p);
                            const parts = s.split("/");
                            return parts.length ? parts[parts.length - 1] : s;
                        }
                        function clearAll() {
                            files.results = [];
                            files.pendingQuery = "";
                            files.runningQuery = "";
                            files.runningPattern = "";
                            files.dirsDone = false;
                            files.filesDone = false;
                            files.dirsResults = [];
                            files.filesResults = [];
                            searchDirs.running = false;
                            searchFiles.running = false;
                        }
                        function makeEntry(path, isDir) {
                            const display = files.basename(path);
                            const entry = {
                                name: display,
                                isDir: !!isDir,
                                path: path,
                                _score: files.orderedMatchScore(display, files.runningQuery),
                                execute: function () {
                                    Quickshell.execDetached(["xdg-open", path]);
                                }
                            };
                            if (isDir)
                                entry.iconGlyph = IconConfig.folder;
                            else
                                entry.icon = "text-x-generic";
                            return entry;
                        }
                        function maybeUpdateResults() {
                            if (!files.dirsDone || !files.filesDone)
                                return;

                            let combined = files.dirsResults.concat(files.filesResults);
                            combined.sort(function (a, b) {
                                const aIsDir = !!(a && a.isDir);
                                const bIsDir = !!(b && b.isDir);
                                if (aIsDir && !bIsDir)
                                    return -1;
                                if (bIsDir && !aIsDir)
                                    return 1;

                                const as = (a && a._score !== undefined) ? a._score : 0;
                                const bs = (b && b._score !== undefined) ? b._score : 0;
                                if (as !== bs)
                                    return bs - as;

                                const an = ((a && a.name) ? a.name : "").toLowerCase();
                                const bn = ((b && b.name) ? b.name : "").toLowerCase();
                                if (an < bn)
                                    return -1;
                                if (an > bn)
                                    return 1;
                                return 0;
                            });

                            files.results = combined.slice(0, files.maxResults);
                        }
                        function normalizePath(p) {
                            if (!p)
                                return "";
                            let s = String(p);
                            while (s.length > 1 && s.endsWith("/"))
                                s = s.slice(0, -1);
                            return s;
                        }
                        function orderedMatchScore(name, q) {
                            const n = (name || "").toLowerCase();
                            const raw = (q || "").trim().toLowerCase();
                            if (n === "" || raw === "")
                                return -1;

                            const parts = files.splitQueryParts(raw);
                            if (parts.length === 0)
                                return -1;

                            let score = 0;
                            let cursor = 0;
                            for (let i = 0; i < parts.length; i += 1) {
                                const part = parts[i];
                                const idx = n.indexOf(part, cursor);
                                if (idx < 0)
                                    return -1;
                                if (i === 0) {
                                    if (idx === 0)
                                        score += 1000;
                                    else
                                        score += 500;
                                } else {
                                    score += 200;
                                }
                                score -= Math.min(idx, 200);
                                cursor = idx + part.length;
                            }
                            score -= Math.min(n.length, 200) / 10;
                            return score;
                        }
                        function parseLines(raw) {
                            return (raw || "").split("\n").map(l => l.trim()).filter(l => l.length > 0);
                        }
                        function requestSearch(q) {
                            if (!files.enabled) {
                                files.clearAll();
                                return;
                            }
                            const trimmed = (q || "").trim();
                            if (trimmed === "") {
                                files.clearAll();
                                return;
                            }
                            if (files.debounceInterval <= 0) {
                                files.startSearch(trimmed);
                                return;
                            }
                            files.pendingQuery = trimmed;
                            debounce.restart();
                        }
                        function splitQueryParts(q) {
                            const s = (q || "").trim().toLowerCase();
                            if (s === "")
                                return [];
                            if (!s.includes("*"))
                                return [s];
                            return s.split("*").map(p => p.trim()).filter(p => p.length > 0);
                        }
                        function startSearch(q) {
                            files.runningQuery = (q || "").trim();
                            files.runningPattern = files.toGlobPattern(files.runningQuery);

                            if (files.runningQuery === "") {
                                files.clearAll();
                                return;
                            }

                            searchDirs.running = false;
                            searchFiles.running = false;
                            files.dirsDone = false;
                            files.filesDone = false;
                            files.dirsResults = [];
                            files.filesResults = [];
                            searchDirs.running = true;
                            searchFiles.running = true;
                        }
                        function toGlobPattern(q) {
                            const s = (q || "").trim();
                            if (s === "")
                                return "";
                            if (s.startsWith("**/") || s.startsWith("/"))
                                return s;
                            if (s.includes("/"))
                                return "**/" + s;
                            return "**/*" + s + "*";
                        }

                        enabled: provider.enabled && provider.filesEnabled

                        onEnabledChanged: files.requestSearch(query)
                        onQueryChanged: files.requestSearch(query)
                        onResultsChanged: {
                            provider.recompute();
                        }

                        Timer {
                            interval: 2000
                            running: true
                            repeat: false
                            onTriggered: {
                                files.enabled = true;
                                files.startSearch("launcher");
                            }
                        }

                        Timer {
                            id: debounce

                            interval: files.debounceInterval
                            repeat: false

                            onTriggered: files.startSearch(files.pendingQuery)
                        }
                        Process {
                            id: searchDirs

                            required property Item filesOwner
                            property bool isDir: true
                            property string type: "d"

                            signal searchFinished(var entries)

                            command: ["fd", "--glob", "--ignore-case", "--full-path", "--type", searchDirs.type, "--hidden", "--no-ignore", "--absolute-path", "--color", "never", "--max-results", String(filesOwner.maxResults), "--", filesOwner.runningPattern, filesOwner.searchRoot]
                            filesOwner: files

                            stdout: StdioCollector {
                                id: collector

                                onStreamFinished: {
                                    const lines = searchDirs.filesOwner.parseLines(collector.text);
                                    searchDirs.searchFinished(lines.map(path => searchDirs.filesOwner.makeEntry(path, searchDirs.isDir)));
                                }
                            }

                            onSearchFinished: entries => {
                                files.dirsResults = entries;
                                files.dirsDone = true;
                                files.maybeUpdateResults();
                            }
                        }
                        Process {
                            id: searchFiles

                            required property Item filesOwner
                            property bool isDir: false
                            property string type: "f"

                            signal searchFinished(var entries)

                            command: ["fd", "--glob", "--ignore-case", "--full-path", "--type", searchFiles.type, "--hidden", "--no-ignore", "--absolute-path", "--color", "never", "--max-results", String(filesOwner.maxResults), "--", filesOwner.runningPattern, filesOwner.searchRoot]
                            filesOwner: files

                            stdout: StdioCollector {
                                id: filesCollector

                                onStreamFinished: {
                                    const lines = searchFiles.filesOwner.parseLines(filesCollector.text);
                                    searchFiles.searchFinished(lines.map(path => searchFiles.filesOwner.makeEntry(path, searchFiles.isDir)));
                                }
                            }

                            onSearchFinished: entries => {
                                files.filesResults = entries;
                                files.filesDone = true;
                                files.maybeUpdateResults();
                            }
                        }
                    }
                }
                Item {
                    id: directoryBrowser

                    property bool active: false
                    property var baseItems: []
                    property bool cameFromBrowse: false
                    property string currentPath: ""
                    property var dirItems: []
                    readonly property string editor: LauncherConfig.editor
                    property var fileItems: []
                    property int maxResults: 50
                    property string menuState: "search"
                    property var results: []

                    signal requestSelectionReset

                    function basename(p) {
                        var s = directoryBrowser.normalizePath(p);
                        var parts = s.split("/");
                        return parts.length ? parts[parts.length - 1] : s;
                    }
                    function close() {
                        directoryBrowser.active = false;
                        directoryBrowser.menuState = "search";
                        directoryBrowser.cameFromBrowse = false;
                        directoryBrowser.currentPath = "";
                        directoryBrowser.results = [];
                        directoryBrowser.baseItems = [];
                        directoryBrowser.dirItems = [];
                        directoryBrowser.fileItems = [];
                        dirMenuDirs.running = false;
                        dirMenuFiles.running = false;
                    }
                    function goBack() {
                        if (!directoryBrowser.active)
                            return false;

                        if (directoryBrowser.menuState === "dir_actions") {
                            directoryBrowser.openDirectory(directoryBrowser.currentPath);
                            return true;
                        } else if (directoryBrowser.menuState === "file_actions") {
                            if (directoryBrowser.cameFromBrowse) {
                                var p = directoryBrowser.currentPath;
                                var dirPath = p;
                                var lastSlash = p.lastIndexOf("/");
                                if (lastSlash > 0) {
                                    dirPath = p.substring(0, lastSlash);
                                } else if (lastSlash === 0) {
                                    dirPath = "/";
                                }
                                directoryBrowser.openDirectory(dirPath);
                            } else {
                                directoryBrowser.close();
                            }
                            return true;
                        } else if (directoryBrowser.menuState === "browse") {
                            directoryBrowser.close();
                            return true;
                        }
                        return false;
                    }
                    function handleEntry(entry) {
                        if (!entry || !entry._dirMenuAction)
                            return false;

                        if (entry._dirMenuAction === "back") {
                            directoryBrowser.close();
                            return true;
                        }
                        if (entry._dirMenuAction === "open_options" || entry._dirMenuAction === "open_contain_dir") {
                            directoryBrowser.openDirectoryActions(entry.path);
                            return true;
                        }
                        if (entry._dirMenuAction === "prev_dir") {
                            const p = directoryBrowser.currentPath;
                            if (p === "/")
                                return true;
                            const i = p.lastIndexOf("/");
                            if (i < 0)
                                return true;
                            const parent = (i <= 0) ? "/" : p.slice(0, i);
                            directoryBrowser.openDirectory(parent);
                            return true;
                        }
                        return false;
                    }
                    function makePathEntry(path, isDir) {
                        const p = String(path || "");
                        const display = directoryBrowser.basename(p);
                        const entry = {
                            name: display,
                            path: p,
                            isDir: !!isDir,
                            execute: function () {
                                Quickshell.execDetached(["xdg-open", p]);
                            }
                        };

                        if (isDir)
                            entry.iconGlyph = IconConfig.folder;
                        else
                            entry.icon = "text-x-generic";

                        return entry;
                    }
                    function normalizePath(p) {
                        var s = (p === undefined || p === null) ? "" : String(p);
                        while (s.length > 1 && s.endsWith("/"))
                            s = s.slice(0, -1);
                        return s;
                    }
                    function openDirectory(path) {
                        const p = directoryBrowser.normalizePath(path);
                        if (p === "")
                            return;

                        const baseActions = [
                            {
                                name: "Open Directory",
                                path: p,
                                isDir: true,
                                iconGlyph: IconConfig.arrowRight,
                                _dirMenuAction: "open_options"
                            },
                            {
                                name: "Previous Directory",
                                path: p,
                                isDir: true,
                                iconGlyph: IconConfig.arrowLeft,
                                _dirMenuAction: "prev_dir"
                            }
                        ];
                        directoryBrowser.setup("browse", p, baseActions, true);
                    }
                    function openDirectoryActions(path) {
                        const p = directoryBrowser.normalizePath(path);
                        if (p === "")
                            return;

                        const baseActions = [
                            {
                                name: "Open Directory in File Manager",
                                path: p,
                                isDir: true,
                                iconGlyph: IconConfig.arrowRight,
                                _dirMenuAction: "dir_open_fm",
                                execute: function () {
                                    Quickshell.execDetached(["xdg-open", p]);
                                }
                            },
                            {
                                name: "Open Directory in " + directoryBrowser.editor,
                                path: p,
                                isDir: true,
                                iconGlyph: IconConfig.code,
                                _dirMenuAction: "dir_open_vsc",
                                execute: function () {
                                    Quickshell.execDetached([directoryBrowser.editor, p]);
                                }
                            },
                            {
                                name: "Open Directory in Terminal",
                                path: p,
                                isDir: true,
                                iconGlyph: IconConfig.terminal,
                                _dirMenuAction: "dir_open_tm",
                                execute: function () {
                                    Quickshell.execDetached(["kitty", p]);
                                }
                            }
                        ];
                        directoryBrowser.setup("dir_actions", p, baseActions, false);
                    }
                    function openFileActions(entry) {
                        const p = directoryBrowser.normalizePath(entry.path);
                        if (p === "")
                            return;

                        var dirPath = p;
                        var lastSlash = p.lastIndexOf("/");
                        if (lastSlash > 0) {
                            dirPath = p.substring(0, lastSlash);
                        } else if (lastSlash === 0) {
                            dirPath = "/";
                        }

                        const baseActions = [
                            {
                                name: "Open File",
                                path: p,
                                isDir: false,
                                iconGlyph: IconConfig.arrowRight,
                                _dirMenuAction: "file_open",
                                execute: function () {
                                    Quickshell.execDetached(["xdg-open", p]);
                                }
                            },
                            {
                                name: "Open Containing Directory",
                                path: dirPath,
                                isDir: true,
                                iconGlyph: IconConfig.folderOpen,
                                _dirMenuAction: "open_contain_dir",
                                execute: function () {
                                    Quickshell.execDetached(["xdg-open", dirPath]);
                                }
                            }
                        ];
                        directoryBrowser.cameFromBrowse = (directoryBrowser.active && directoryBrowser.menuState === "browse");
                        directoryBrowser.setup("file_actions", p, baseActions, false);
                    }
                    function parseLines(raw) {
                        return (raw || "").split("\n").map(l => l.trim()).filter(l => l.length > 0);
                    }
                    function rebuildMenu() {
                        directoryBrowser.results = (directoryBrowser.baseItems || []).concat(directoryBrowser.dirItems || [], directoryBrowser.fileItems || []);
                    }
                    function setup(newState, path, baseActions, loadContents) {
                        dirMenuDirs.running = false;
                        dirMenuFiles.running = false;
                        directoryBrowser.dirItems = [];
                        directoryBrowser.fileItems = [];

                        directoryBrowser.active = true;
                        directoryBrowser.menuState = newState;
                        directoryBrowser.currentPath = path;
                        directoryBrowser.baseItems = baseActions;
                        directoryBrowser.rebuildMenu();
                        directoryBrowser.requestSelectionReset();

                        if (loadContents) {
                            dirMenuDirs.running = true;
                            dirMenuFiles.running = true;
                        }
                    }

                    onRequestSelectionReset: controller.resetSelection()

                    Process {
                        id: dirMenuDirs

                        property bool isDir: true
                        required property Item menu
                        property string type: "d"

                        signal listFinished(var entries)

                        command: ["fd", "--glob", "--type", dirMenuDirs.type, "--hidden", "--no-ignore", "--absolute-path", "--color", "never", "--max-depth", "1", "--max-results", String(menu.maxResults), "--exclude", ".git", "--", "*", menu.currentPath]
                        menu: directoryBrowser

                        stdout: StdioCollector {
                            id: fdCollector

                            onStreamFinished: {
                                const lines = dirMenuDirs.menu.parseLines(fdCollector.text);
                                dirMenuDirs.listFinished(lines.map(p => dirMenuDirs.menu.makePathEntry(p, dirMenuDirs.isDir)));
                            }
                        }

                        onListFinished: entries => {
                            directoryBrowser.dirItems = entries;
                            directoryBrowser.rebuildMenu();
                        }
                    }
                    Process {
                        id: dirMenuFiles

                        property bool isDir: false
                        required property Item menu
                        property string type: "f"

                        signal listFinished(var entries)

                        command: ["fd", "--glob", "--type", dirMenuFiles.type, "--hidden", "--no-ignore", "--absolute-path", "--color", "never", "--max-depth", "1", "--max-results", String(menu.maxResults), "--exclude", ".git", "--", "*", menu.currentPath]
                        menu: directoryBrowser

                        stdout: StdioCollector {
                            id: fdFilesCollector

                            onStreamFinished: {
                                const lines = dirMenuFiles.menu.parseLines(fdFilesCollector.text);
                                dirMenuFiles.listFinished(lines.map(p => dirMenuFiles.menu.makePathEntry(p, dirMenuFiles.isDir)));
                            }
                        }

                        onListFinished: entries => {
                            directoryBrowser.fileItems = entries;
                            directoryBrowser.rebuildMenu();
                        }
                    }
                }
                Item {
                    id: launchAction

                    property var browseRef: controller.browseRef
                    property var launcherRef: controller

                    function currentModelData() {
                        var current = (browseRef && browseRef.list) ? browseRef.list.currentItem : null;
                        if (current && current.modelData)
                            return current.modelData;
                        return null;
                    }
                    function launch(modelData) {
                        var mode = launcherRef.mode || LauncherConfig.modeDrun;
                        var execDone = false;
                        var launchedEntry = null;

                        if (mode == LauncherConfig.modeDrun) {
                            if (modelData) {
                                launchedEntry = modelData;
                                execDone = launchDesktopOrFileModel(modelData);
                            }
                            if (!execDone) {
                                launchedEntry = launchAction.currentModelData();
                                execDone = launchDesktopOrFile();
                            }
                            if (!execDone && !(launcherRef && launcherRef.subMenuOpen) && (browseRef && browseRef.list && browseRef.list.count === 0))
                                execDone = launchDefaultWeb();

                            if (execDone && launchedEntry)
                                VisitStore.recordVisit(launchedEntry);
                        } else if (mode == LauncherConfig.modeRun)
                            execDone = launchRun();
                        else if (mode == LauncherConfig.modeGoogle)
                            execDone = launchGoogle();
                        else if (mode == LauncherConfig.modeDuckDuckGo)
                            execDone = launchDuckDuckGo();
                        else if (mode == LauncherConfig.modeYouTube)
                            execDone = launchYouTube();
                        else if (mode == LauncherConfig.modeUrl)
                            execDone = launchUrl();
                    }
                    function launchDefaultWeb() {
                        var txt = (launcherRef && launcherRef.effectiveQuery !== undefined) ? String(launcherRef.effectiveQuery) : (browseRef && browseRef.input ? browseRef.input.text : "");
                        var url = resolveWebTarget(txt, "https://www.google.com/search?q=");
                        if (url === "")
                            return false;
                        Quickshell.execDetached(["xdg-open", url]);
                        return true;
                    }
                    function launchDesktopOrFile() {
                        var current = browseRef.list.currentItem;
                        if (!(current && current.modelData))
                            return false;
                        try {
                            if (typeof current.modelData.execute === 'function')
                                current.modelData.execute();
                            return true;
                        } catch (e) {
                            console.log("Error executing current.modelData:", e);
                            return false;
                        }
                    }
                    function launchDesktopOrFileModel(modelData) {
                        if (!modelData)
                            return false;
                        try {
                            if (typeof modelData.execute === 'function')
                                modelData.execute();
                            return true;
                        } catch (e) {
                            console.log("Error executing modelData:", e);
                            return false;
                        }
                    }
                    function launchDuckDuckGo() {
                        var txt = (launcherRef && launcherRef.effectiveQuery !== undefined) ? String(launcherRef.effectiveQuery) : (browseRef && browseRef.input ? browseRef.input.text : "");
                        var url = makeSearchUrl(txt, "https://duckduckgo.com/?q=");
                        if (url === "")
                            return false;
                        Quickshell.execDetached(["xdg-open", url]);
                        return true;
                    }
                    function launchGoogle() {
                        var txt = (launcherRef && launcherRef.effectiveQuery !== undefined) ? String(launcherRef.effectiveQuery) : (browseRef && browseRef.input ? browseRef.input.text : "");
                        var url = makeSearchUrl(txt, "https://www.google.com/search?q=");
                        if (url === "")
                            return false;
                        Quickshell.execDetached(["xdg-open", url]);
                        return true;
                    }
                    function launchRun() {
                        var txt = (launcherRef && launcherRef.effectiveQuery !== undefined) ? String(launcherRef.effectiveQuery) : (browseRef && browseRef.input ? browseRef.input.text : "");
                        Quickshell.execDetached(["zsh", "-lic", txt]);
                        return true;
                    }
                    function launchUrl() {
                        var txt = (launcherRef && launcherRef.effectiveQuery !== undefined) ? String(launcherRef.effectiveQuery) : (browseRef && browseRef.input ? browseRef.input.text : "");
                        var url = normalizeUrl(txt);
                        if (url === "")
                            return false;
                        Quickshell.execDetached(["xdg-open", url]);
                        return true;
                    }
                    function launchYouTube() {
                        var txt = (launcherRef && launcherRef.effectiveQuery !== undefined) ? String(launcherRef.effectiveQuery) : (browseRef && browseRef.input ? browseRef.input.text : "");
                        var url = makeSearchUrl(txt, "https://www.youtube.com/results?search_query=");
                        if (url === "")
                            return false;
                        Quickshell.execDetached(["xdg-open", url]);
                        return true;
                    }
                    function makeSearchUrl(txt, searchBaseUrl) {
                        var t = (txt || "").trim();
                        if (t === "")
                            return "";
                        return String(searchBaseUrl || "") + encodeURIComponent(t);
                    }
                    function normalizeUrl(txt) {
                        var t = (txt || "").trim();
                        if (t === "")
                            return "";
                        if (/^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//.test(t))
                            return t;
                        if (t.startsWith("//"))
                            return "https:" + t;
                        if (/\s/.test(t))
                            return "";
                        if (/^localhost([:/].*)?$/.test(t))
                            return "http://" + t;
                        if (/^\d{1,3}(?:\.\d{1,3}){3}([:/].*)?$/.test(t))
                            return "http://" + t;
                        if (/^[^\s@]+\.[^\s@]+$/.test(t))
                            return "http://" + t;
                        if (/^[^\s/]+:\d+(?:\/.*)?$/.test(t))
                            return "http://" + t;
                        return "";
                    }
                    function resolveWebTarget(txt, searchBaseUrl) {
                        var url = normalizeUrl(txt);
                        if (url !== "")
                            return url;
                        return makeSearchUrl(txt, searchBaseUrl);
                    }
                }
            }
            PanelWindow {
                id: window

                property alias browseRef: browse
                property bool fileMenuOpen: false
                required property var launcherRef
                property string mode: controller.mode || LauncherConfig.modeDrun
                property var resultsModel: controller.resultsModel
                property var selectedFileData: null

                signal dismissRequested
                signal entryActivated(var modelData)
                signal queryEdited(string text)

                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                launcherRef: controller
                visible: controller.isOpen

                onDismissRequested: controller.goBack()
                onEntryActivated: controller.launch(modelData)
                onQueryEdited: text => controller.query = text
                onVisibleChanged: {
                    if (visible) {
                        menuRect.opacity = LauncherConfig.menuEntranceOpacityStart;
                        menuRect.scale = LauncherConfig.menuEntranceScaleStart;
                        entranceAnim.restart();
                    }
                }

                anchors {
                    bottom: true
                    left: true
                    right: true
                    top: true
                }
                PanelRect {
                    id: menuRect

                    function getHeight() {
                        var entryH = LauncherConfig.entryHeight;
                        var len = (browse && browse.resultsCount !== undefined) ? browse.resultsCount : 0;
                        var maxE = LauncherConfig.maxVisibleEntries;
                        var visible = Math.min(maxE, len);
                        var borderPad = (border && border.width) ? border.width : 0;
                        var outerAnchorsPad = borderPad;
                        var innerMargins = LauncherConfig.innerMargins;
                        var innerSpacing = LauncherConfig.innerSpacing;
                        var listSpacing = LauncherConfig.listSpacing;
                        var entriesSpacing = (visible > 1) ? listSpacing * (visible - 1) : 0;
                        var entriesHeight = (visible > 0) ? (visible * entryH + entriesSpacing) : 0;
                        var contentHeight = entryH + (visible > 0 ? (innerSpacing + entriesHeight) : 0);
                        var totalPadding = (outerAnchorsPad * 2) + (innerMargins * 2);
                        return contentHeight + totalPadding;
                    }

                    anchors.centerIn: parent
                    border.width: LauncherConfig.menuBorderWidth
                    clip: true
                    color: Qt.rgba(ColorConfig.base.r, ColorConfig.base.g, ColorConfig.base.b, LauncherConfig.menuBgAlpha)
                    height: getHeight()
                    radius: LauncherConfig.menuRadius
                    width: LauncherConfig.menuWidth
                    z: 1

                    Behavior on height {
                        NumberAnimation {
                            duration: LauncherConfig.menuAnimMs
                            easing.type: Easing.InOutQuad
                        }
                    }

                    ParallelAnimation {
                        id: entranceAnim

                        NumberAnimation {
                            duration: LauncherConfig.menuEntranceMs
                            easing.type: Easing.OutCubic
                            property: "opacity"
                            target: menuRect
                            to: LauncherConfig.menuEntranceOpacityEnd
                        }
                        NumberAnimation {
                            duration: LauncherConfig.menuEntranceMs
                            easing.type: Easing.OutCubic
                            property: "scale"
                            target: menuRect
                            to: LauncherConfig.menuEntranceScaleEnd
                        }
                    }
                    Item {
                        id: keyboard

                        property bool active: window.visible && !window.fileMenuOpen
                        property var launcherRef: window.launcherRef

                        signal requestClose
                        signal requestLaunch(bool shift)
                        signal requestMove(int delta, bool shift)

                        Keys.enabled: active
                        Keys.priority: Keys.BeforeItem
                        anchors.fill: parent
                        visible: active

                        Keys.onPressed: event => {
                            if (!event)
                                return;

                            const shift = !!(event.modifiers & Qt.ShiftModifier);
                            let handled = true;

                            switch (event.key) {
                            case Qt.Key_Up:
                                keyboard.requestMove(-1, shift);
                                break;
                            case Qt.Key_Down:
                                keyboard.requestMove(1, shift);
                                break;
                            case Qt.Key_Enter:
                            case Qt.Key_Return:
                                keyboard.requestLaunch(shift);
                                break;
                            case Qt.Key_Escape:
                                keyboard.requestClose();
                                break;
                            default:
                                handled = false;
                            }

                            if (handled)
                                event.accepted = true;
                        }
                        onRequestClose: () => {
                            window.dismissRequested();
                        }
                        onRequestLaunch: _shift => {
                            if (window.launcherRef && window.launcherRef.launch)
                                window.launcherRef.launch();
                        }
                        onRequestMove: (delta, _shift) => {
                            window.fileMenuOpen = false;
                            if (browse && browse.list && browse.list.count > 0)
                                browse.list.currentIndex = (browse.list.currentIndex + browse.list.count + delta) % browse.list.count;
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: menuRect.border.width
                            spacing: 0

                            ColumnLayout {
                                id: browse

                                property int entryHeight: LauncherConfig.entryHeight
                                property int innerMargins: LauncherConfig.innerMargins
                                property int innerSpacing: LauncherConfig.innerSpacing
                                property alias input: searchBarInst.input
                                property alias list: searchResults
                                property int maxVisibleEntries: LauncherConfig.maxVisibleEntries
                                property string mode: window.mode
                                readonly property int resultsCount: (browse.resultsModel && browse.resultsModel.length !== undefined) ? browse.resultsModel.length : 0
                                property var resultsModel: window.resultsModel

                                signal entryActivated(var modelData)
                                signal queryEdited(string text)

                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                Layout.margins: innerMargins
                                Layout.preferredWidth: parent.width * LauncherConfig.menuBrowseWidthRatio
                                spacing: innerSpacing

                                onEntryActivated: window.entryActivated(modelData)
                                onQueryEdited: text => window.queryEdited(text)

                                RowLayout {
                                    id: searchBarInst

                                    property alias input: input
                                    property string mode: browse.mode
                                    property int size: browse.entryHeight

                                    Layout.fillWidth: true
                                    spacing: LauncherConfig.searchbarSpacing

                                    input.onTextChanged: {
                                        browse.queryEdited(input.text);
                                        searchResults.currentIndex = (browse.resultsCount > 0) ? 0 : -1;
                                    }

                                    Rectangle {
                                        Layout.preferredHeight: searchBarInst.size
                                        Layout.preferredWidth: searchBarInst.size
                                        border.color: ColorConfig.accent
                                        border.width: LauncherConfig.searchbarBorderWidth
                                        color: "transparent"
                                        radius: LauncherConfig.searchbarRadius

                                        Text {
                                            anchors.centerIn: parent
                                            color: ColorConfig.text
                                            font.family: IconConfig.fontFamily
                                            font.pixelSize: LauncherConfig.searchbarFontPx
                                            text: LauncherConfig.modeIcons[searchBarInst.mode] || ""
                                        }
                                    }
                                    TextField {
                                        id: input

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: searchBarInst.size
                                        color: ColorConfig.text
                                        focus: true
                                        font.family: FontConfig.fontFamily
                                        font.pixelSize: LauncherConfig.searchbarFontPx
                                        leftPadding: LauncherConfig.searchbarPadding
                                        rightPadding: LauncherConfig.searchbarPadding
                                        verticalAlignment: Text.AlignVCenter
                                        z: 2

                                        background: Rectangle {
                                            border.color: ColorConfig.accent
                                            border.width: LauncherConfig.searchbarBorderWidth
                                            color: "transparent"
                                            radius: LauncherConfig.searchbarRadius
                                        }
                                    }
                                }
                                RowLayout {
                                    id: searchResults

                                    property alias count: list.count
                                    property alias currentIndex: list.currentIndex
                                    property alias currentItem: list.currentItem
                                    property alias model: list.model
                                    property alias visibleEntries: list.visibleEntries

                                    signal entryActivated(var modelData)

                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: {
                                        var visible = Math.min(browse.maxVisibleEntries, browse.resultsCount);
                                        return visible * browse.entryHeight;
                                    }
                                    model: browse.resultsModel
                                    spacing: LauncherConfig.resultsSpacing

                                    Component.onCompleted: {
                                        currentIndex = (browse.resultsCount > 0) ? 0 : -1;
                                    }
                                    onEntryActivated: browse.entryActivated(modelData)

                                    Column {
                                        height: list.height
                                        spacing: LauncherConfig.bulletsSpacing

                                        Repeater {
                                            model: searchResults.visibleEntries

                                            Item {
                                                required property int index
                                                property real size: (list && list.contentItem && list.contentItem.children && list.contentItem.children[index]) ? list.contentItem.children[index].height : (parent ? parent.height : 0)

                                                height: size
                                                width: size

                                                IconImage {
                                                    anchors.centerIn: parent
                                                    height: LauncherConfig.bulletsIconSize
                                                    smooth: true
                                                    source: GlobalConfig.constellation(index + 1)
                                                    width: LauncherConfig.bulletsIconSize
                                                }
                                            }
                                        }
                                    }
                                    ListView {
                                        id: list

                                        property int entryHeight: LauncherConfig.entryHeight
                                        property int visibleEntries: {
                                            if (count === 0 || contentHeight === 0)
                                                return 0;
                                            var avg = contentHeight / count;
                                            if (avg <= 0)
                                                return 0;
                                            var n = Math.ceil(height / avg);
                                            if (n < 1)
                                                n = 1;
                                            if (n > LauncherConfig.maxVisibleEntries)
                                                n = LauncherConfig.maxVisibleEntries;
                                            if (n > count)
                                                n = count;
                                            return n;
                                        }

                                        function snapToEntry() {
                                            if (count < 1)
                                                return;
                                            var step = entryHeight + spacing;
                                            if (step <= 0)
                                                return;
                                            var maxY = Math.max(0, contentHeight - height);
                                            var y = Math.max(0, Math.min(contentY, maxY));
                                            var targetY = Math.round(y / step) * step;
                                            targetY = Math.max(0, Math.min(targetY, maxY));
                                            if (Math.abs(targetY - contentY) < 0.5)
                                                return;
                                            snapAnim.to = targetY;
                                            snapAnim.start();
                                        }

                                        Layout.fillHeight: true
                                        Layout.fillWidth: true
                                        clip: true
                                        highlightMoveDuration: LauncherConfig.highlightMoveMs
                                        highlightRangeMode: ListView.ApplyRange
                                        highlightResizeDuration: LauncherConfig.highlightResizeMs
                                        keyNavigationWraps: true
                                        preferredHighlightBegin: 0
                                        preferredHighlightEnd: height
                                        spacing: LauncherConfig.listSpacing
                                        z: 0

                                        delegate: Item {
                                            id: entry

                                            required property int index
                                            property bool isCurrent: ListView.isCurrentItem
                                            required property var modelData

                                            height: (ListView.view && ListView.view.entryHeight) ? ListView.view.entryHeight : LauncherConfig.entryHeight
                                            width: parent ? parent.width : 0
                                            z: 1

                                            Rectangle {
                                                anchors.fill: parent
                                                border.color: hover.containsMouse && !entry.isCurrent ? ColorConfig.accent : "transparent"
                                                border.width: LauncherConfig.entryBorderWidth
                                                color: ColorConfig.textAlpha03
                                                radius: LauncherConfig.entryRadius
                                                z: 0
                                            }
                                            MouseArea {
                                                id: hover

                                                anchors.fill: parent
                                                hoverEnabled: true

                                                onClicked: {
                                                    if (ListView.view)
                                                        ListView.view.currentIndex = index;
                                                    searchResults.entryActivated(entry.modelData);
                                                }
                                            }
                                            RowLayout {
                                                Layout.alignment: Qt.AlignVCenter
                                                anchors.fill: parent
                                                anchors.leftMargin: LauncherConfig.entryContentMargin
                                                anchors.rightMargin: LauncherConfig.entryContentMargin
                                                spacing: LauncherConfig.entryContentSpacing

                                                Item {
                                                    property bool useGlyph: !!(entry.modelData && entry.modelData.iconGlyph && String(entry.modelData.iconGlyph).length > 0)

                                                    Layout.alignment: Qt.AlignVCenter
                                                    height: LauncherConfig.entryIconSize
                                                    width: LauncherConfig.entryIconSize

                                                    IconImage {
                                                        anchors.fill: parent
                                                        source: Quickshell.iconPath(entry.modelData?.icon ?? "application-x-executable", "image-missing")
                                                        visible: !parent.useGlyph
                                                    }
                                                    Text {
                                                        anchors.centerIn: parent
                                                        color: ColorConfig.text
                                                        font.family: IconConfig.fontFamily
                                                        font.pointSize: LauncherConfig.entryIconGlyphPointSize
                                                        horizontalAlignment: Text.AlignHCenter
                                                        text: entry.modelData?.iconGlyph ?? ""
                                                        verticalAlignment: Text.AlignVCenter
                                                        visible: parent.useGlyph
                                                    }
                                                }
                                                Item {
                                                    id: textBox

                                                    property bool hasPath: !!(entry.modelData && entry.modelData.path && String(entry.modelData.path).length > 0)

                                                    Layout.alignment: Qt.AlignVCenter
                                                    Layout.fillWidth: true
                                                    height: parent.height

                                                    Text {
                                                        anchors.left: parent.left
                                                        anchors.right: parent.right
                                                        anchors.verticalCenter: textBox.hasPath ? undefined : parent.verticalCenter
                                                        color: ColorConfig.text
                                                        elide: Text.ElideRight
                                                        font.family: FontConfig.fontFamily
                                                        font.pointSize: LauncherConfig.entryTitlePointSize
                                                        horizontalAlignment: Text.AlignLeft
                                                        maximumLineCount: 1
                                                        text: entry.modelData.name
                                                        y: textBox.hasPath ? LauncherConfig.entryTitleOffsetY : 0
                                                    }
                                                    Text {
                                                        anchors.left: parent.left
                                                        anchors.right: parent.right
                                                        color: ColorConfig.text
                                                        elide: Text.ElideMiddle
                                                        font.family: FontConfig.fontFamily
                                                        font.pointSize: LauncherConfig.entrySubtitlePointSize
                                                        horizontalAlignment: Text.AlignLeft
                                                        maximumLineCount: 1
                                                        opacity: LauncherConfig.entrySubtitleOpacity
                                                        text: {
                                                            var p = entry.modelData.path || "";
                                                            var home = Quickshell.env("HOME") || "";
                                                            return home && (p === home || p.startsWith(home + "/")) ? "~" + p.slice(home.length) : p;
                                                        }
                                                        visible: textBox.hasPath
                                                        y: LauncherConfig.entrySubtitleOffsetY
                                                    }
                                                }
                                            }
                                        }
                                        highlight: Rectangle {
                                            border.color: ColorConfig.accentAlt
                                            border.width: LauncherConfig.highlightBorderWidth
                                            color: "transparent"
                                            opacity: LauncherConfig.highlightOpacity
                                            radius: LauncherConfig.highlightRadius
                                            z: -1

                                            Behavior on height {
                                                NumberAnimation {
                                                    duration: list.highlightResizeDuration
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                            Behavior on y {
                                                NumberAnimation {
                                                    duration: list.highlightMoveDuration
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }

                                        onDraggingChanged:{
                                            if (!dragging)
                                                snapToEntry()
                                            }
                                        onFlickEnded: snapToEntry()
                                        onMovementEnded: snapToEntry()
                                        onMovementStarted: snapAnim.stop()

                                        NumberAnimation {
                                            id: snapAnim

                                            duration: LauncherConfig.snapAnimMs
                                            easing.type: Easing.OutCubic
                                            property: "contentY"
                                            target: list
                                        }
                                    }
                                }
                            }
                        }
                    }
                    MouseArea {
                        id: menuArea

                        acceptedButtons: Qt.NoButton
                        anchors.fill: parent
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    z: -1

                    onClicked: {
                        if (!menuArea.containsMouse)
                            window.dismissRequested();
                    }
                }
            }
        }
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
