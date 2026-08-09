pragma ComponentBehavior: Bound

import QtQuick

import qs.launcher.service

Item {
    id: root

    property bool filesEnabled: true
    property int maxResults: 50
    property string pendingQuery: ""
    property string query: ""
    property var results: []
    property string runningQuery: ""
    property string searchRoot: "/"

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
    AppsProvider {
        id: apps

        query: root.runningQuery

        onResultsChanged: root.recompute()
    }
    FilesProvider {
        id: files

        debounceInterval: 0
        enabled: root.enabled && root.filesEnabled
        maxResults: root.maxResults
        query: root.runningQuery
        searchRoot: root.searchRoot

        onResultsChanged: root.recompute()
    }
}
