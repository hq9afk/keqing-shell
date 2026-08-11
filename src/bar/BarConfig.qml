pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

import qs.config

QtObject {
    // Bar
    readonly property real backgroundOpacity: 0
    readonly property int barContentFadeMs: 300
    readonly property int barHeight: 35
    readonly property real barHiddenOpacity: 0
    readonly property int barMarginH: 20
    readonly property int barMarginTop: 10
    readonly property real barVisibleOpacity: 1

    // Battery
    readonly property int batteryBarHeight: 8
    readonly property int batteryBarRadius: 4
    readonly property int batteryEmptyStateHeight: 50

    // Bluetooth
    readonly property int bluetoothConnectFailClearMs: 4000
    readonly property real bluetoothDeviceDisconnectedOpacity: 0.6
    readonly property int bluetoothEmptyStateHeight: 96
    readonly property int bluetoothOffStateHeight: 72
    readonly property int bluetoothRetryButtonPaddingH: 20
    readonly property int bluetoothScanTimeoutMs: 30000
    readonly property int bluetoothSectionGapLarge: 24
    readonly property int bluetoothSectionGapSmall: 20

    // Calendar
    readonly property int calendarCellCirclePadding: 4
    readonly property int calendarGridTopGap: 2
    readonly property real calendarTodayDimOpacity: 0.4
    readonly property int calendarWeekdayRowHeight: 22

    // Capsule
    readonly property int capsuleBorderWidth: 2
    readonly property int capsuleHeight: barHeight
    readonly property int capsuleLabelAnimMs: 200
    readonly property real capsuleLabelHiddenOpacity: 0
    readonly property real capsuleLabelVisibleOpacity: 1
    readonly property int capsuleLingerMs: 80
    readonly property int capsuleRadius: GlobalConfig.radiusMd

    // Dock
    readonly property int dockIconAnimMs: 150
    readonly property real dockIconFocusedOpacity: 1
    readonly property real dockIconUnfocusedOpacity: 0.5
    readonly property int dockReorderAnimMs: 200

    // DropPanel
    readonly property int dropPanelDefaultContentHeight: 200
    readonly property int dropPanelDefaultContentWidth: 300

    // Typography
    readonly property int iconSize: 18

    // Profile Card
    readonly property int logoBorderWidth: 5

    // Network
    readonly property real networkConnectDisabledOpacity: 0.4
    readonly property int networkErrorBannerPaddingV: 16
    readonly property int networkErrorCloseRadius: 9
    readonly property int networkErrorCloseSize: 18
    readonly property int networkErrorTextWidthOffset: 60
    readonly property int networkEthernetBannerHeight: 40
    readonly property int networkPasswordFieldBorderWidth: 1
    readonly property int networkRowHeight: 52
    readonly property int networkScanDotIntervalMs: 400
    readonly property int networkScanningStateHeight: 48
    readonly property int networkSectionGapLarge: 24
    readonly property int networkSectionGapSmall: 20
    readonly property int networkUnavailableStateHeight: 72

    // Panel
    readonly property int panelActionButtonRadius: 11
    readonly property int panelActionButtonSize: 22
    readonly property int panelBarColorAnimMs: 200
    readonly property int panelBarWidthAnimMs: 300
    readonly property int panelBorderWidth: 2
    readonly property int panelCloseButtonRadius: 10
    readonly property int panelCloseButtonSize: 20
    readonly property int panelConfirmButtonRadius: 6
    readonly property int panelConfirmButtonSize: 28
    readonly property int panelContentGap: 8
    readonly property int panelDeviceRowHeight: 50
    readonly property int panelDialogButtonPaddingH: 16
    readonly property int panelDialogSpacerHeight: 14
    readonly property int panelGap: 8
    readonly property int panelHeaderDividerGap: 4
    readonly property int panelHeaderHeight: 32
    readonly property int panelListRowRadius: 8
    readonly property int panelListSpacing: 5
    readonly property int panelPadding: 20
    readonly property int panelRadius: GlobalConfig.radiusMd
    readonly property int panelRowActionGap: 4
    readonly property int panelRowGap: 6
    readonly property int panelRowIconGap: 8
    readonly property int panelSectionGap: 10
    readonly property int panelStatusDotRadius: 4
    readonly property int panelStatusDotSize: 8
    readonly property int panelSubPanelRowHeight: 28
    readonly property int panelSubPanelTopMargin: 6
    readonly property int panelTightGap: 4
    readonly property int panelTrailingSpacerHeight: 4
    readonly property int panelWidthCalendar: 280
    readonly property int panelWidthMedium: 320
    readonly property int panelWidthSmall: 300
    readonly property int screenMargin: 20

    // SystemMonitor
    readonly property int sysMonitorBarHeight: 5
    readonly property int sysMonitorBarRadius: 3
    readonly property int sysMonitorNetLabelWidth: 60

    // Tray
    readonly property int trayButtonRadius: 6
    readonly property int trayCellIconPadding: 16
    readonly property int trayColumns: 5
    readonly property int trayGridSpacing: 4
    readonly property int trayHeaderContentGap: 12

    // TrayMenu
    readonly property int trayMenuBorderWidth: 1
    readonly property int trayMenuItemHeight: 28
    readonly property int trayMenuLabelWidthOffset: 24
    readonly property real trayMenuMaxHeightRatio: 0.9
    readonly property int trayMenuPadding: 4
    readonly property int trayMenuRadiusExtra: 3
    readonly property int trayMenuRowPaddingH: 8
    readonly property int trayMenuSeparatorHeight: 8
    readonly property int trayMenuSeparatorLineHeight: 1
    readonly property int trayMenuSeparatorWidthOffset: 12
    readonly property int trayMenuSubmenuOffsetX: 60
    readonly property int trayMenuTopPad: 8
    readonly property int trayMenuWidth: 220

    // Volume
    readonly property int volumeAppListTopGap: 4
    readonly property int volumeAppRowBottomPad: 8
    readonly property int volumeAppSliderHeight: 16
    readonly property int volumeDeviceIndicatorDotRadius: 3
    readonly property int volumeDeviceIndicatorDotSize: 6
    readonly property int volumeDeviceIndicatorRadius: 7
    readonly property int volumeDeviceIndicatorSize: 14
    readonly property int volumeDeviceRowBottomPad: 6
    readonly property int volumeLabelWidthCap: 180
    readonly property int volumePeekMs: 2000
    readonly property int volumePeekReadyDelayMs: 1000
    readonly property int volumePercentLabelWidth: 40
    readonly property int volumeRowHeight: 24
    readonly property int volumeSectionHeaderPad: 6
    readonly property int volumeSliderHeight: 20
    readonly property int volumeSliderRightGap: 8

    // Widget
    readonly property int widgetContentPaddingH: 16
    readonly property real widgetSpacing: 10

    // Workspace
    readonly property real workspaceActiveWidthScale: 2
    readonly property int workspaceFlashOffMs: 200
    readonly property int workspaceFlashOnMs: 250
    readonly property int workspaceLayoutSpacing: 8
    readonly property int workspacePillAnimMs: 150
    readonly property int workspacePillHeight: 12
    readonly property int workspacePillSpacing: 5
    readonly property int workspaceReorderAnimMs: 200
}
