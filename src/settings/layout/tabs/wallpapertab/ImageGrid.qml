pragma ComponentBehavior: Bound

import QtQuick

import qs.settings
import qs.wallpaper
import qs.config

Rectangle {
    id: imageGrid

    property var imageFiles: []
    property var previewSources: ({})
    property string selectedScreen: ""
    readonly property var sortedFiles: {
        var files = imageGrid.imageFiles.slice();
        files.sort(function (a, b) {
            var extA = a.split('.').pop().toLowerCase();
            var extB = b.split('.').pop().toLowerCase();
            if (extA !== extB)
                return extA < extB ? -1 : 1;
            var nameA = a.split('/').pop().toLowerCase();
            var nameB = b.split('/').pop().toLowerCase();
            return nameA < nameB ? -1 : nameA > nameB ? 1 : 0;
        });
        return files;
    }
    property var wallpapers: ({})

    signal wallpaperSelected(string path)

    border.color: ColorConfig.accent
    border.width: GlobalConfig.borderWidthThin
    clip: true
    color: "transparent"
    radius: GlobalConfig.radiusSm + SettingsConfig.thumbnailRadiusBoost

    GridView {
        id: grid

        readonly property real cellSize: width / WallpaperConfig.imagesPerRow

        anchors.fill: parent
        anchors.margins: WallpaperConfig.gridBorderWidth
        cellHeight: cellSize
        cellWidth: cellSize
        clip: true
        model: imageGrid.sortedFiles

        delegate: Item {
            required property string modelData

            height: grid.cellHeight
            width: grid.cellWidth

            WallpaperThumbnail {
                anchors.fill: parent
                anchors.margins: Math.round(grid.cellSize * SettingsConfig.thumbnailInnerMarginRatio)
                path: modelData
                previewSource: imageGrid.previewSources[modelData] ?? ""
                selected: imageGrid.wallpapers[imageGrid.selectedScreen] === modelData

                onClicked: path => imageGrid.wallpaperSelected(path)
            }
        }
    }
}
