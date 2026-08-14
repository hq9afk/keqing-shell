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
    readonly property string videoPath: (WallpaperService.animatedWallpapers[root.screenName] ?? [])[root.columnIndex] ?? ""

    height: root.rect.h * parent.height
    width: root.rect.w * parent.width
    x: root.rect.x * parent.width
    y: root.rect.y * parent.height
    z: 1

    MediaPlayer {
        id: animatedPlayer

        readonly property string optimizedPath: WallpaperService.animatedOptimized[root.videoPath] ?? ""

        loops: MediaPlayer.Infinite
        source: WallpaperService.animatedEnabled && optimizedPath && !root.paused ? "file://" + optimizedPath : ""
        videoOutput: animatedOutput

        onSourceChanged: if (source !== "")
            play()

        Component.onDestruction: {
            animatedPlayer.stop();
            animatedPlayer.source = "";
        }
    }
    VideoOutput {
        id: animatedOutput

        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: animatedPlayer.source !== ""
    }
    Image {
        anchors.centerIn: parent
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        height: parent.height * 0.5
        smooth: true
        source: WallpaperService.loaded && WallpaperService.animatedEnabled && animatedPlayer.optimizedPath === "" ? GlobalConfig.defaultWallpaper : ""
        sourceSize: Qt.size(0, height)
        visible: WallpaperService.loaded && WallpaperService.animatedEnabled && animatedPlayer.optimizedPath === ""
        width: parent.width * 0.5
    }
}
