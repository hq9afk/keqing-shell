pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.components
import qs.service
import qs.settings.layout.tabs.wallpapertab
import qs.wallpaper
import qs.config

Item {
    ColumnLayout {
        anchors.fill: parent
        spacing: WallpaperConfig.columnSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: WallpaperConfig.controlRowHeight

            Text {
                Layout.alignment: Qt.AlignVCenter
                color: ColorConfig.text
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontSettingsBody
                text: "Enable animated wallpaper"
            }
            Item {
                Layout.fillWidth: true
            }
            Toggle {
                Layout.alignment: Qt.AlignVCenter
                active: WallpaperService.animatedEnabled

                onToggled: WallpaperService.setAnimatedEnabled(!active)
            }
        }
        StaticWallpaperSubtab {
            Layout.fillHeight: true
            Layout.fillWidth: true
            visible: !WallpaperService.animatedEnabled
        }
        AnimatedWallpaperSubtab {
            Layout.fillHeight: true
            Layout.fillWidth: true
            visible: WallpaperService.animatedEnabled
        }
    }
}
