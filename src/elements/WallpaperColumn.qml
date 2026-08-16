pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia

import qs.service
import qs.config

Item {
    id: root

    required property int columnCount
    required property int columnIndex
    property bool paused: false
    readonly property var rect: ({
            x: root.columnIndex / root.columnCount,
            y: 0,
            w: 1 / root.columnCount,
            h: 1
        })
    required property string screenName
    readonly property string optimizedPath: WallpaperService.animatedOptimized[root.videoPath] ?? ""
    readonly property bool showingDefault: WallpaperService.loaded && WallpaperService.defaultEnabled && (WallpaperService.animatedEnabled ? root.optimizedPath === "" : root.wallpaperPath === "")
    readonly property string videoPath: (WallpaperService.animatedWallpapers[root.screenName] ?? [])[root.columnIndex] ?? ""
    readonly property var wallpaperArray: WallpaperService.staticWallpapers[root.screenName] ?? []
    readonly property string wallpaperPath: root.wallpaperArray[root.columnIndex] ?? ""

    function resolvedAnimatedFillMode() {
        switch ((WallpaperService.animatedFillModes[root.screenName] ?? [])[root.columnIndex] ?? "crop") {
        case "fit":
            return VideoOutput.PreserveAspectFit;
        default:
            return VideoOutput.PreserveAspectCrop;
        }
    }
    function resolvedSourceSize(src, w, h) {
        return String(src).toLowerCase().endsWith(".svg") ? Qt.size(0, h) : Qt.size(w, h);
    }
    function resolvedStaticFillMode() {
        switch ((WallpaperService.staticFillModes[root.screenName] ?? [])[root.columnIndex] ?? "crop") {
        case "fit":
            return Image.PreserveAspectFit;
        default:
            return Image.PreserveAspectCrop;
        }
    }

    height: root.rect.h * parent.height
    width: root.rect.w * parent.width
    x: root.rect.x * parent.width
    y: root.rect.y * parent.height
    z: 1

    Loader {
        active: WallpaperService.animatedEnabled
        anchors.fill: parent

        sourceComponent: Item {
            MediaPlayer {
                id: animatedPlayer

                loops: MediaPlayer.Infinite
                source: root.optimizedPath && !root.paused ? "file://" + root.optimizedPath : ""
                videoOutput: animatedOutput

                Component.onDestruction: {
                    animatedPlayer.stop();
                    animatedPlayer.source = "";
                }
                onSourceChanged: if (source !== "")
                    play()
            }
            VideoOutput {
                id: animatedOutput

                anchors.fill: parent
                fillMode: root.resolvedAnimatedFillMode()
                visible: animatedPlayer.source !== ""
            }
        }
    }
    Loader {
        active: !WallpaperService.animatedEnabled
        anchors.fill: parent

        sourceComponent: Image {
            id: wallpaperImage

            asynchronous: true
            fillMode: root.resolvedStaticFillMode()
            smooth: true
            source: root.wallpaperPath ? "file://" + root.wallpaperPath : ""
            sourceSize: root.resolvedSourceSize(wallpaperImage.source, root.width, root.height)
            visible: wallpaperImage.source !== ""
        }
    }
    Image {
        anchors.centerIn: parent
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        height: parent.height * 0.5
        smooth: true
        source: root.showingDefault ? GlobalConfig.defaultWallpaper : ""
        sourceSize: Qt.size(0, height)
        visible: root.showingDefault
        width: parent.width * 0.5
    }
}
