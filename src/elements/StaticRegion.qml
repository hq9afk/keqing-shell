pragma ComponentBehavior: Bound

import QtQuick

import qs.service
import qs.config

Item {
    id: root

    required property int columnCount
    required property int columnIndex
    readonly property var fillArray: WallpaperService.staticFillModes[root.screenName] ?? []
    readonly property var rect: ({
            x: root.columnIndex / root.columnCount,
            y: 0,
            w: 1 / root.columnCount,
            h: 1
        })
    required property string screenName
    readonly property var wallpaperArray: WallpaperService.staticWallpapers[root.screenName] ?? []
    readonly property string wallpaperPath: root.wallpaperArray[root.columnIndex] ?? ""

    function resolvedFillMode() {
        switch (root.fillArray[root.columnIndex] ?? "crop") {
        case "fit":
            return Image.PreserveAspectFit;
        case "stretch":
            return Image.Stretch;
        case "tile":
            return Image.Tile;
        default:
            return Image.PreserveAspectCrop;
        }
    }
    function resolvedSourceSize(src, w, h) {
        return String(src).toLowerCase().endsWith(".svg") ? Qt.size(0, h) : Qt.size(w, h);
    }

    height: root.rect.h * parent.height
    width: root.rect.w * parent.width
    x: root.rect.x * parent.width
    y: root.rect.y * parent.height

    Image {
        id: wallpaperImage

        anchors.fill: parent
        asynchronous: true
        fillMode: root.resolvedFillMode()
        smooth: true
        source: root.wallpaperPath ? "file://" + root.wallpaperPath : ""
        sourceSize: root.resolvedSourceSize(wallpaperImage.source, root.width, root.height)
        visible: root.wallpaperPath !== ""
    }
    Image {
        anchors.centerIn: parent
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        height: parent.height * 0.5
        smooth: true
        source: WallpaperService.loaded && root.wallpaperPath === "" ? GlobalConfig.defaultWallpaper : ""
        sourceSize: Qt.size(0, height)
        visible: WallpaperService.loaded && root.wallpaperPath === ""
        width: parent.width * 0.5
    }
}
