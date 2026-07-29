pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.wallpaper

QtObject {
    id: root

    property var animatedColumns: ({})
    property string animatedDir: Quickshell.env("HOME") + "/Videos"
    property bool animatedEnabled: false
    property Process animatedFileProc: Process {
        id: animatedFileProc

        property string scanDir: ""
        readonly property string thumbScript: `cache="${root.cacheDir}video-thumbs"
mkdir -p "$cache"
find -L "$1" -maxdepth 2 -type f \\( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" \\) | while IFS= read -r f; do
    hash=$(printf "%s" "$f" | md5sum | cut -d" " -f1)
    out="$cache/$hash.jpg"
    [ -f "$out" ] || ffmpeg -y -loglevel error -ss 0 -i "$f" -frames:v 1 -vf scale=320:-1 "$out" >/dev/null 2>&1
    printf "%s\\t%s\\n" "$f" "$out"
done`

        command: ["bash", "-c", thumbScript, "bash", scanDir]

        stdout: StdioCollector {}

        onExited: {
            root.animatedScanning = false;
            var lines = animatedFileProc.stdout.text.split('\n').filter(l => l.trim() !== '');
            var files = [];
            var thumbs = {};
            for (var i = 0; i < lines.length; i++) {
                var parts = lines[i].split('\t');
                if (parts.length === 2) {
                    files.push(parts[0]);
                    thumbs[parts[0]] = parts[1];
                }
            }
            root.animatedFiles = files;
            root.animatedThumbnails = thumbs;
        }
    }
    property var animatedFiles: []
    property var animatedOptimized: ({})
    property var animatedOptimizing: ({})
    property bool animatedScanning: false
    property var animatedThumbnails: ({})
    property var animatedWallpapers: ({})
    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/keqing-shell/"
    property FileView cacheView: FileView {
        id: cacheView

        printErrors: false
        watchChanges: false

        adapter: JsonAdapter {
            id: cacheAdapter

            property var animatedColumns: ({})
            property string animatedDir: ""
            property bool animatedEnabled: false
            property var animatedWallpapers: ({})
            property var staticColumns: ({})
            property string staticDir: ""
            property var staticFillModes: ({})
            property var staticWallpapers: ({})
        }

        onLoadFailed: {
            root.scanStatic(root.staticDir);
            root.scanAnimated(root.animatedDir);
            root.loaded = true;
        }
        onLoaded: {
            root.staticWallpapers = Object.assign({}, cacheAdapter.staticWallpapers || {});
            root.staticFillModes = Object.assign({}, cacheAdapter.staticFillModes || {});
            root.animatedWallpapers = Object.assign({}, cacheAdapter.animatedWallpapers || {});
            root.staticColumns = Object.assign({}, cacheAdapter.staticColumns || {});
            root.animatedColumns = Object.assign({}, cacheAdapter.animatedColumns || {});
            root.animatedEnabled = cacheAdapter.animatedEnabled || false;
            if (cacheAdapter.animatedDir !== "")
                root.animatedDir = cacheAdapter.animatedDir;
            if (cacheAdapter.staticDir !== "")
                root.staticDir = cacheAdapter.staticDir;
            root.scanStatic(root.staticDir);
            root.scanAnimated(root.animatedDir);
            var animatedScreens = Object.keys(root.animatedWallpapers);
            for (var s = 0; s < animatedScreens.length; s++) {
                var arr = root.animatedWallpapers[animatedScreens[s]] || [];
                for (var c = 0; c < arr.length; c++)
                    if (arr[c])
                        root.optimizeAnimatedWallpaper(arr[c]);
            }
            saveTimer.restart();
            root.loaded = true;
        }
    }
    readonly property string configDir: Quickshell.env("HOME") + "/.config/keqing-shell/"
    property bool loaded: false
    property Process mkdirProc: Process {
        id: mkdirProc

        command: ["mkdir", "-p", root.cacheDir]

        onExited: cacheView.path = root.configDir + "wallpapers.json"
    }
    property Process optimizeProc: Process {
        id: optimizeProc

        readonly property string optimizeScript: `src="$1"
cache="${root.cacheDir}video-optimized"
mkdir -p "$cache"
hash=$(printf "%s-${WallpaperConfig.animatedMaxHeight}x${WallpaperConfig.animatedMaxFps}" "$src" | md5sum | cut -d" " -f1)
out="$cache/$hash.mp4"
if [ -f "$out" ]; then
    printf "%s\\t%s\\n" "$src" "$out"
    exit 0
fi
srcH=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$src" 2>/dev/null)
srcFps=$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of csv=p=0 "$src" 2>/dev/null)
fpsOk=$(awk -F/ -v max="${WallpaperConfig.animatedMaxFps}" '{r=(NF==2 && $2>0)?$1/$2:$1} END{print (r<=max)?1:0}' <<< "$srcFps")
if [ -n "$srcH" ] && [ "$srcH" -le ${WallpaperConfig.animatedMaxHeight} ] 2>/dev/null && [ "$fpsOk" = "1" ]; then
    cp "$src" "$out"
else
    ffmpeg -y -loglevel error -i "$src" -vf "scale=-2:${WallpaperConfig.animatedMaxHeight},fps=${WallpaperConfig.animatedMaxFps}" -c:v libx264 -preset veryfast -movflags +faststart "$out" >/dev/null 2>&1
fi
[ -f "$out" ] && printf "%s\\t%s\\n" "$src" "$out"`
        property string srcPath: ""

        command: ["bash", "-c", optimizeScript, "bash", srcPath]

        stdout: StdioCollector {}

        onExited: {
            var line = optimizeProc.stdout.text.trim();
            var parts = line.split('\t');
            if (parts.length === 2) {
                var updated = Object.assign({}, root.animatedOptimized);
                updated[parts[0]] = parts[1];
                root.animatedOptimized = updated;
            }
            var opting = Object.assign({}, root.animatedOptimizing);
            delete opting[optimizeProc.srcPath];
            root.animatedOptimizing = opting;
            root.processOptimizeQueue();
        }
    }
    property var optimizeQueue: []
    property Timer saveTimer: Timer {
        id: saveTimer

        interval: 500
        repeat: false

        onTriggered: {
            cacheAdapter.staticWallpapers = root.staticWallpapers;
            cacheAdapter.staticFillModes = root.staticFillModes;
            cacheAdapter.staticDir = root.staticDir;
            cacheAdapter.animatedEnabled = root.animatedEnabled;
            cacheAdapter.animatedWallpapers = root.animatedWallpapers;
            cacheAdapter.animatedDir = root.animatedDir;
            cacheAdapter.staticColumns = root.staticColumns;
            cacheAdapter.animatedColumns = root.animatedColumns;
            cacheView.writeAdapter();
        }
    }
    property var staticColumns: ({})
    property string staticDir: Quickshell.env("WALLPAPER_DIR") || (Quickshell.env("HOME") + "/Pictures")
    property Process staticFileProc: Process {
        id: staticFileProc

        property string scanDir: ""

        command: ["find", "-L", scanDir, "-maxdepth", "2", "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", "-o", "-iname", "*.gif", ")"]

        stdout: StdioCollector {}

        onExited: {
            root.staticScanning = false;
            var lines = staticFileProc.stdout.text.split('\n').filter(l => l.trim() !== '');
            root.staticFiles = lines.filter(f => /\.(jpg|jpeg|png|webp|gif)$/i.test(f));
        }
    }
    property var staticFiles: []
    property var staticFillModes: ({})
    property bool staticScanning: false
    property var staticWallpapers: ({})

    signal staticWallpaperChanged(string screenName, string path)

    function optimizeAnimatedWallpaper(path) {
        if (!path)
            return;
        if (root.animatedOptimized[path])
            return;
        if (root.animatedOptimizing[path])
            return;
        if (root.optimizeQueue.indexOf(path) !== -1)
            return;
        var opting = Object.assign({}, root.animatedOptimizing);
        opting[path] = true;
        root.animatedOptimizing = opting;
        root.optimizeQueue = root.optimizeQueue.concat([path]);
        root.processOptimizeQueue();
    }
    function processOptimizeQueue() {
        if (optimizeProc.running)
            return;
        if (root.optimizeQueue.length === 0)
            return;
        var next = root.optimizeQueue[0];
        root.optimizeQueue = root.optimizeQueue.slice(1);
        optimizeProc.srcPath = next;
        optimizeProc.running = true;
    }
    function removeAnimatedWallpaper(screenName, columnIndex) {
        var updated = Object.assign({}, animatedWallpapers);
        var arr = (updated[screenName] || []).slice();
        if (columnIndex < arr.length)
            arr[columnIndex] = "";
        updated[screenName] = arr;
        animatedWallpapers = updated;
        saveTimer.restart();
    }
    function removeStaticWallpaper(screenName, columnIndex) {
        var updated = Object.assign({}, staticWallpapers);
        var arr = (updated[screenName] || []).slice();
        if (columnIndex < arr.length)
            arr[columnIndex] = "";
        updated[screenName] = arr;
        staticWallpapers = updated;
        saveTimer.restart();
        staticWallpaperChanged(screenName, "");
    }
    function resized(arr, n, fill) {
        var a = (arr || []).slice();
        while (a.length < n)
            a.push(fill);
        a.length = n;
        return a;
    }
    function scanAnimated(dir) {
        if (!dir)
            return;
        root.animatedScanning = true;
        root.animatedFiles = [];
        if (animatedFileProc.running)
            animatedFileProc.running = false;
        animatedFileProc.scanDir = dir;
        animatedFileProc.running = true;
    }
    function scanStatic(dir) {
        if (!dir)
            return;
        root.staticScanning = true;
        root.staticFiles = [];
        if (staticFileProc.running)
            staticFileProc.running = false;
        staticFileProc.scanDir = dir;
        staticFileProc.running = true;
    }
    function setAnimatedColumns(screenName, n) {
        var clamped = Math.max(1, n);
        var updatedCols = Object.assign({}, animatedColumns);
        updatedCols[screenName] = clamped;
        animatedColumns = updatedCols;
        var updatedWallpapers = Object.assign({}, animatedWallpapers);
        updatedWallpapers[screenName] = root.resized(updatedWallpapers[screenName], clamped, "");
        animatedWallpapers = updatedWallpapers;
        saveTimer.restart();
    }
    function setAnimatedDir(path) {
        if (!path)
            return;
        var expanded = path;
        if (expanded === "~")
            expanded = Quickshell.env("HOME");
        else if (expanded.startsWith("~/"))
            expanded = Quickshell.env("HOME") + expanded.slice(1);
        if (expanded === animatedDir) {
            scanAnimated(animatedDir);
            return;
        }
        animatedDir = expanded;
        saveTimer.restart();
        scanAnimated(animatedDir);
    }
    function setAnimatedEnabled(enabled) {
        root.animatedEnabled = enabled;
        saveTimer.restart();
    }
    function setAnimatedWallpaper(screenName, columnIndex, path) {
        var updated = Object.assign({}, animatedWallpapers);
        var arr = (updated[screenName] || []).slice();
        while (arr.length <= columnIndex)
            arr.push("");
        arr[columnIndex] = path;
        updated[screenName] = arr;
        animatedWallpapers = updated;
        saveTimer.restart();
        if (path)
            root.optimizeAnimatedWallpaper(path);
    }
    function setStaticColumns(screenName, n) {
        var clamped = Math.max(1, n);
        var updatedCols = Object.assign({}, staticColumns);
        updatedCols[screenName] = clamped;
        staticColumns = updatedCols;
        var updatedWallpapers = Object.assign({}, staticWallpapers);
        updatedWallpapers[screenName] = root.resized(updatedWallpapers[screenName], clamped, "");
        staticWallpapers = updatedWallpapers;
        var updatedFillModes = Object.assign({}, staticFillModes);
        updatedFillModes[screenName] = root.resized(updatedFillModes[screenName], clamped, "crop");
        staticFillModes = updatedFillModes;
        saveTimer.restart();
    }
    function setStaticDir(path) {
        if (!path)
            return;
        var expanded = path;
        if (expanded === "~")
            expanded = Quickshell.env("HOME");
        else if (expanded.startsWith("~/"))
            expanded = Quickshell.env("HOME") + expanded.slice(1);
        if (expanded === staticDir) {
            scanStatic(staticDir);
            return;
        }
        staticDir = expanded;
        saveTimer.restart();
        scanStatic(staticDir);
    }
    function setStaticFillMode(screenName, columnIndex, mode) {
        var updated = Object.assign({}, staticFillModes);
        var arr = (updated[screenName] || []).slice();
        while (arr.length <= columnIndex)
            arr.push("crop");
        arr[columnIndex] = mode;
        updated[screenName] = arr;
        staticFillModes = updated;
        saveTimer.restart();
    }
    function setStaticWallpaper(screenName, columnIndex, path) {
        var updated = Object.assign({}, staticWallpapers);
        var arr = (updated[screenName] || []).slice();
        while (arr.length <= columnIndex)
            arr.push("");
        arr[columnIndex] = path;
        updated[screenName] = arr;
        staticWallpapers = updated;
        saveTimer.restart();
        staticWallpaperChanged(screenName, path);
    }

    Component.onCompleted: mkdirProc.running = true
}
