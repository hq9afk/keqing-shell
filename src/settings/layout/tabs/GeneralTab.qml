pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.service
import qs.settings
import qs.settings.layout.components
import qs.config

Flickable {
    id: root

    clip: true
    contentHeight: col.implicitHeight

    Column {
        id: col

        spacing: SettingsConfig.tabColumnSpacing
        width: root.width

        SettingsGroup {
            title: "Appearance"
            width: col.width

            Item {
                height: SettingsConfig.generalTabRowHeight
                width: parent.width

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: ColorConfig.text
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontSettingsBody
                    font.weight: Font.DemiBold
                    opacity: SettingsConfig.labelOpacity
                    text: "Font Family"
                }
                DropdownMenu {
                    activeValue: FontConfig.fontFamily
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    model: {
                        const local = [FontConfig.yujiMaiLoader.name, IconConfig.fontFamily];
                        return Qt.fontFamilies().filter(f => !local.includes(f)).sort();
                    }
                    selfFont: true

                    onItemSelected: value => SettingsService.setFontFamily(value)
                }
            }
        }
    }
}
