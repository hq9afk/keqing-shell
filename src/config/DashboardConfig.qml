pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

QtObject {

    // Battery
    readonly property int batteryBarHeight: 6
    readonly property int batteryBarRadius: 3
    readonly property int batteryColorAnimMs: 300
    readonly property int batteryHeaderSpacing: 10
    readonly property int batteryRowSpacing: 8
    readonly property int batteryTextSpacing: 2
    readonly property int batteryWidthAnimMs: 400

    // Card
    readonly property int cardBorderWidth: 1
    readonly property int cardBottomPadding: 12
    readonly property int cardHeaderContentGap: 8
    readonly property int cardHeaderHeight: 32
    readonly property int cardHorizontalPadding: 12
    readonly property int cardRadius: 12
    readonly property int cardTopPadding: 10

    // Media
    readonly property int mediaCtrlRowHeight: 32
    readonly property int mediaCtrlSpacing: 8
    readonly property int mediaCtrlTopMargin: 8
    readonly property int mediaPlayBtnRadius: 16
    readonly property int mediaPlayBtnSize: 32
    readonly property int mediaProgressRowHeight: 20
    readonly property int mediaProgressTopMargin: 10
    readonly property int mediaSideBtnRadius: 14
    readonly property int mediaSideBtnSize: 28
    readonly property int mediaThumbRadius: 8
    readonly property int mediaThumbSize: 72
    readonly property int mediaTitleLeftMargin: 12
    readonly property int mediaTitleSpacing: 3

    // Panel
    readonly property int panelColumnSpacing: 10
    readonly property int panelWidth: 360

    // Profile
    readonly property int profileAvatarGap: 8
    readonly property int profileAvatarSize: 100
    readonly property int profileBorderWidth: 1
    readonly property int profileContentSpacing: 10
    readonly property int profileHorizontalPadding: 14
    readonly property int profileInfoSpacing: 2
    readonly property int profileInfoTextWidth: 200
    readonly property int profileRadius: 12
    readonly property int profileSettingsHitPadding: 8
    readonly property int profileTopPadding: 12
    readonly property int profileVerticalPadding: 24

    // Stats
    readonly property int statsColumnGap: 16
    readonly property int statsGaugeLabelSpacing: 4
    readonly property int statsSpacing: 10

    // Temperature
    readonly property int cpuCoreColumns: 2
    readonly property int cpuCoreColumnSpacing: 8
    readonly property int cpuCoreItemHeight: 24
    readonly property int cpuCoreItemRadius: 6
    readonly property int cpuCoreRowSpacing: 6
    readonly property int cpuCoreTextMargin: 8
    readonly property int cpuTempGridTopMargin: 8
    readonly property int tempRowHeight: 26

    // Volume
    readonly property int volumeCardSpacing: 8
    readonly property int volumeDeviceTextMaxWidth: 148
    readonly property int volumeLabelRowSpacing: 4
    readonly property int volumeMuteBtnRadius: 11
    readonly property int volumeMuteBtnSize: 22
    readonly property int volumePctMuteGap: 6
    readonly property int volumePctTextWidth: 40
    readonly property int volumeRowSpacing: 4
    readonly property int volumeSliderHeight: 20
    readonly property int volumeSliderPctGap: 8
    readonly property int volumeSliderRowHeight: 24
}
