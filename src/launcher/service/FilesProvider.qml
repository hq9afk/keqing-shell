pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.config

Item {
    id: root

    property int debounceInterval: 120
    property bool dirsDone: false
    property var dirsResults: []
    property bool filesDone: false
    property var filesResults: []
    property int maxResults: 50
    property string pendingQuery: ""
    property string query: ""
    property var results: []
    property string runningPattern: ""
    property string runningQuery: ""
    property string searchRoot: "/"

    function basename(p) {
        if (!p)
            return "";
        const s = root.normalizePath(p);
        const parts = s.split("/");
        return parts.length ? parts[parts.length - 1] : s;
    }
    function clearAll() {
        root.results = [];
        root.pendingQuery = "";
        root.runningQuery = "";
        root.runningPattern = "";
        root.dirsDone = false;
        root.filesDone = false;
        root.dirsResults = [];
        root.filesResults = [];
        searchDirs.running = false;
        searchFiles.running = false;
    }
    function makeEntry(path, isDir) {
        const display = root.basename(path);
        const entry = {
            name: display,
            isDir: !!isDir,
            path: path,
            _score: root.orderedMatchScore(display, root.runningQuery),
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
        if (!root.dirsDone || !root.filesDone)
            return;

        let combined = root.dirsResults.concat(root.filesResults);
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

        root.results = combined.slice(0, root.maxResults);
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

        const parts = root.splitQueryParts(raw);
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
        if (!root.enabled) {
            root.clearAll();
            return;
        }
        const trimmed = (q || "").trim();
        if (trimmed === "") {
            root.clearAll();
            return;
        }
        if (root.debounceInterval <= 0) {
            root.startSearch(trimmed);
            return;
        }
        root.pendingQuery = trimmed;
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
        root.runningQuery = (q || "").trim();
        root.runningPattern = root.toGlobPattern(root.runningQuery);

        if (root.runningQuery === "") {
            root.clearAll();
            return;
        }

        searchDirs.running = false;
        searchFiles.running = false;
        root.dirsDone = false;
        root.filesDone = false;
        root.dirsResults = [];
        root.filesResults = [];
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

    enabled: false

    onEnabledChanged: root.requestSearch(query)
    onQueryChanged: root.requestSearch(query)

    Timer {
        id: debounce

        interval: root.debounceInterval
        repeat: false

        onTriggered: root.startSearch(root.pendingQuery)
    }
    Search {
        id: searchDirs

        isDir: true
        type: "d"

        onSearchFinished: entries => {
            root.dirsResults = entries;
            root.dirsDone = true;
            root.maybeUpdateResults();
        }
    }
    Search {
        id: searchFiles

        isDir: false
        type: "f"

        onSearchFinished: entries => {
            root.filesResults = entries;
            root.filesDone = true;
            root.maybeUpdateResults();
        }
    }

    component Search: Process {
        id: search

        property bool isDir
        property string type

        signal searchFinished(var entries)

        command: ["fd", "--glob", "--ignore-case", "--full-path", "--type", search.type, "--hidden", "--no-ignore", "--absolute-path", "--color", "never", "--max-results", String(root.maxResults), "--", root.runningPattern, root.searchRoot]

        stdout: StdioCollector {
            id: collector

            onStreamFinished: {
                const lines = root.parseLines(collector.text);
                search.searchFinished(lines.map(path => root.makeEntry(path, search.isDir)));
            }
        }
    }
}
