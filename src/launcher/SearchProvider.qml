pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.config
import qs.service

Item {
    id: root

    property bool filesEnabled: true
    property int maxResults: 50
    required property var mode
    property string pendingQuery: ""
    required property string query
    property var results: []
    property string runningQuery: ""
    required property string searchRoot

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
        const q = (root.runningQuery || "").trim();
        const qLower = q.toLowerCase();

        if (!root.enabled || qLower === "") {
            root.results = [];
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
                score: root.computeAppScore(it, qLower),
                visits: visits,
                nameLower: (it && it.name) ? String(it.name).toLowerCase() : ""
            });
        }

        const fileRes = files.results || [];
        for (let j = 0; j < fileRes.length; j += 1) {
            const it2 = fileRes[j];
            const score2 = (it2 && it2._score !== undefined) ? it2._score : root.computeAppScore(it2, qLower);
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

        root.results = decorated.slice(0, root.maxResults).map(d => d.item);
    }
    function scheduleQueryUpdate() {
        if (!root.enabled) {
            root.pendingQuery = "";
            root.runningQuery = "";
            root.results = [];
            return;
        }

        const q = (root.query || "");
        if (q.trim() === "") {
            root.pendingQuery = "";
            root.runningQuery = "";
            root.results = [];
            return;
        }

        root.pendingQuery = q;
        queryDebounce.restart();
    }

    enabled: root.mode === LauncherConfig.modeDrun

    onEnabledChanged: scheduleQueryUpdate()
    onFilesEnabledChanged: recompute()
    onMaxResultsChanged: recompute()
    onQueryChanged: scheduleQueryUpdate()

    Connections {
        function onChanged() {
            root.recompute();
        }

        target: VisitStore
    }
    Timer {
        id: queryDebounce

        interval: 120
        repeat: false

        onTriggered: {
            if (!root.enabled) {
                root.runningQuery = "";
                root.results = [];
                return;
            }

            const q = (root.pendingQuery || "").trim();
            root.runningQuery = q;
            root.recompute();
        }
    }
    Item {
        id: apps

        property string query: root.runningQuery
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
        onResultsChanged: root.recompute()
    }
    Item {
        id: files

        property int debounceInterval: 0
        property bool dirsDone: false
        property var dirsResults: []
        property bool filesDone: false
        property var filesResults: []
        property int maxResults: root.maxResults
        property string pendingQuery: ""
        property string query: root.runningQuery
        property var results: []
        property string runningPattern: ""
        property string runningQuery: ""
        property string searchRoot: root.searchRoot

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

        enabled: root.enabled && root.filesEnabled

        onEnabledChanged: files.requestSearch(query)
        onQueryChanged: files.requestSearch(query)
        onResultsChanged: {
            root.recompute();
        }

        Timer {
            interval: 2000
            repeat: false
            running: true

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
