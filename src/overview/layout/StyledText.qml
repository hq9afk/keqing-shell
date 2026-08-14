pragma ComponentBehavior: Bound

import QtQuick

import qs.config

Text {
    id: root

    color: ColorConfig.text
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter

    font {
        family: FontConfig.fontFamily
        hintingPreference: Font.PreferFullHinting
        pixelSize: FontConfig.fontOverviewText
    }
}
