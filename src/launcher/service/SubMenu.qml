pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.launcher
import qs.config

Item {
    id: root

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
        var s = root.normalizePath(p);
        var parts = s.split("/");
        return parts.length ? parts[parts.length - 1] : s;
    }
    function close() {
        root.active = false;
        root.menuState = "search";
        root.cameFromBrowse = false;
        root.currentPath = "";
        root.results = [];
        root.baseItems = [];
        root.dirItems = [];
        root.fileItems = [];
        dirMenuDirs.running = false;
        dirMenuFiles.running = false;
    }
    function goBack() {
        if (!root.active)
            return false;

        if (root.menuState === "dir_actions") {
            root.openDirectory(root.currentPath);
            return true;
        } else if (root.menuState === "file_actions") {
            if (root.cameFromBrowse) {
                var p = root.currentPath;
                var dirPath = p;
                var lastSlash = p.lastIndexOf("/");
                if (lastSlash > 0) {
                    dirPath = p.substring(0, lastSlash);
                } else if (lastSlash === 0) {
                    dirPath = "/";
                }
                root.openDirectory(dirPath);
            } else {
                root.close();
            }
            return true;
        } else if (root.menuState === "browse") {
            root.close();
            return true;
        }
        return false;
    }
    function handleEntry(entry) {
        if (!entry || !entry._dirMenuAction)
            return false;

        if (entry._dirMenuAction === "back") {
            root.close();
            return true;
        }
        if (entry._dirMenuAction === "open_options" || entry._dirMenuAction === "open_contain_dir") {
            root.openDirectoryActions(entry.path);
            return true;
        }
        if (entry._dirMenuAction === "prev_dir") {
            const p = root.currentPath;
            if (p === "/")
                return true;
            const i = p.lastIndexOf("/");
            if (i < 0)
                return true;
            const parent = (i <= 0) ? "/" : p.slice(0, i);
            root.openDirectory(parent);
            return true;
        }
        return false;
    }
    function makePathEntry(path, isDir) {
        const p = String(path || "");
        const display = root.basename(p);
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
        const p = root.normalizePath(path);
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
        root.setup("browse", p, baseActions, true);
    }
    function openDirectoryActions(path) {
        const p = root.normalizePath(path);
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
                name: "Open Directory in " + root.editor,
                path: p,
                isDir: true,
                iconGlyph: IconConfig.code,
                _dirMenuAction: "dir_open_vsc",
                execute: function () {
                    Quickshell.execDetached([root.editor, p]);
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
        root.setup("dir_actions", p, baseActions, false);
    }
    function openFileActions(entry) {
        const p = root.normalizePath(entry.path);
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
        root.cameFromBrowse = (root.active && root.menuState === "browse");
        root.setup("file_actions", p, baseActions, false);
    }
    function parseLines(raw) {
        return (raw || "").split("\n").map(l => l.trim()).filter(l => l.length > 0);
    }
    function rebuildMenu() {
        root.results = (root.baseItems || []).concat(root.dirItems || [], root.fileItems || []);
    }
    function setup(newState, path, baseActions, loadContents) {
        dirMenuDirs.running = false;
        dirMenuFiles.running = false;
        root.dirItems = [];
        root.fileItems = [];

        root.active = true;
        root.menuState = newState;
        root.currentPath = path;
        root.baseItems = baseActions;
        root.rebuildMenu();
        root.requestSelectionReset();

        if (loadContents) {
            dirMenuDirs.running = true;
            dirMenuFiles.running = true;
        }
    }

    FdListProcess {
        id: dirMenuDirs

        isDir: true
        type: "d"

        onListFinished: entries => {
            root.dirItems = entries;
            root.rebuildMenu();
        }
    }
    FdListProcess {
        id: dirMenuFiles

        isDir: false
        type: "f"

        onListFinished: entries => {
            root.fileItems = entries;
            root.rebuildMenu();
        }
    }

    component FdListProcess: Process {
        id: control

        property bool isDir
        property string type

        signal listFinished(var entries)

        command: ["fd", "--glob", "--type", control.type, "--hidden", "--no-ignore", "--absolute-path", "--color", "never", "--max-depth", "1", "--max-results", String(root.maxResults), "--exclude", ".git", "--", "*", root.currentPath]

        stdout: StdioCollector {
            id: collector

            onStreamFinished: {
                const lines = root.parseLines(collector.text);
                control.listFinished(lines.map(p => root.makePathEntry(p, control.isDir)));
            }
        }
    }
}
