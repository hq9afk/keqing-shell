pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

QtObject {
    id: root

    // Window
    readonly property int navRailCollapseBreakpoint: 700
    readonly property real windowCardClosedScale: 0.97
    readonly property int windowCardHeightInset: 80
    readonly property int windowCardMaxHeight: 680
    readonly property int windowCardMaxWidth: 920
    readonly property int windowCardWidthInset: 80
    readonly property real windowCloseIconDimmedOpacity: 0.45
    readonly property int windowCloseHitSlop: -8
    readonly property int windowContentLeftMargin: 16
    readonly property int windowContentMargins: 24
    readonly property int windowRowSpacing: 12
    readonly property int windowTabTopMargin: 12
    readonly property int windowTitleBarHeight: 28
    readonly property int windowTitleSpacerHeight: 16

    // NavRail
    readonly property int navRailAvatarRowLeftMargin: 4
    readonly property int navRailAvatarRowTopMargin: 6
    readonly property int navRailAvatarSize: 44
    readonly property int navRailCollapsedWidth: 64
    readonly property int navRailContentSpacing: 12
    readonly property int navRailCopiedFeedbackMs: 1500
    readonly property int navRailExpandedWidth: 200
    readonly property int navRailFabContentSpacing: 8
    readonly property int navRailFabHeight: 34
    readonly property real navRailInactiveIconOpacity: 0.75
    readonly property real navRailInactiveLabelOpacity: 0.6
    readonly property int navRailItemContentSpacing: 12
    readonly property int navRailItemHeight: 36
    readonly property int navRailItemLeftMargin: 10
    readonly property int navRailItemRightMargin: 8
    readonly property int navRailItemSpacing: 4
    readonly property int navRailListTopMargin: 4
    readonly property int navRailPadding: 14
    readonly property int navRailTightSpacing: 2
    readonly property int navRailUptimeFontSizeAdjust: -3
    readonly property int navRailUsernameFontSizeAdjust: -1

    // Structure
    readonly property int dividerThickness: 1
    readonly property int hairlineBorderWidth: 1
    readonly property int selectorBorderWidth: 2

    // Tabs
    readonly property int colorSchemeTabSpacing: 14
    readonly property int controlCenterCardContentSpacing: 8
    readonly property int controlCenterLabelSpacing: 2
    readonly property int controlCenterRowHeight: 50
    readonly property int fieldRadius: 4
    readonly property int generalTabRowHeight: 40
    readonly property int groupContentSpacingLg: 20
    readonly property int groupContentSpacingSm: 8
    readonly property int iconHoverHitSlop: -6
    readonly property real iconHoverOpacity: 0.9
    readonly property int idleDividerHeight: 20
    readonly property int idleDividerLeftMargin: 2
    readonly property int numberFieldHeight: 28
    readonly property int numberFieldWidth: 72
    readonly property int numericTileHeight: 52
    readonly property int regionPreviewSpacing: 2
    readonly property int reorderItemSpacing: 6
    readonly property int resetPillHeight: 30
    readonly property int resetPillPaddingH: 24
    readonly property int screenSelectorHeight: 35
    readonly property int screenSelectorSpacing: 6
    readonly property int tabBottomSpacerHeight: 8
    readonly property int tabColumnSpacing: 12
    readonly property int tileContentMargin: 12
    readonly property int tileContentSpacing: 10
    readonly property int tileRadius: 6
    readonly property int toggleTileHeight: 48

    // Opacity
    readonly property real charLabelOpacity: 0.7
    readonly property real dimTextOpacity: 0.45
    readonly property real disabledOpacity: 0.4
    readonly property real faintOpacity: 0.3
    readonly property real fieldLabelOpacity: 0.5
    readonly property real hintTextOpacity: 0.4
    readonly property real labelOpacity: 0.85
    readonly property real mutedTextOpacity: 0.55
    readonly property real unselectedOptionOpacity: 0.6

    // Animation
    readonly property int dragReflowAnimMs: 200
    readonly property int quickColorAnimMs: 100
    readonly property int toggleAnimMs: 150

    // Toggle
    readonly property int toggleKnobInset: 3
    readonly property int toggleKnobRadius: 7
    readonly property int toggleKnobSize: 14
    readonly property int toggleRowLabelInset: 44
    readonly property int toggleTrackHeight: 20
    readonly property int toggleTrackRadius: 10
    readonly property int toggleTrackWidth: 36

    // ComboBox
    readonly property int comboBoxHeight: 28
    readonly property int comboBoxTextLeftMargin: 7
    readonly property int comboBoxWidth: 160

    // Dropdown
    readonly property int dropdownMenuMaxHeight: 240
    readonly property int dropdownMenuPadding: 4
    readonly property int dropdownMinWidth: 120
    readonly property int dropdownOptionAnimMs: 80
    readonly property int dropdownOptionHeight: 26
    readonly property int dropdownOptionRadius: 3
    readonly property int dropdownOptionSpacing: 2
    readonly property int dropdownOptionTextMargin: 8
    readonly property int dropdownReopenGuardMs: 100
    readonly property int dropdownTriggerHeight: 30
    readonly property int dropdownTriggerPaddingH: 20
    readonly property int dropdownTriggerSpacing: 6
    readonly property int dropdownYOffset: 2

    // Group
    readonly property int groupExtraHeight: 24
    readonly property int groupPadding: 12
    readonly property int groupRadius: 8
    readonly property int groupSpacing: 8

    // Widget
    readonly property int widgetCardContentMargin: 8
    readonly property int widgetCardContentSpacing: 4
    readonly property int widgetCardHeight: 34
    readonly property int widgetCardRadius: 6
    readonly property int widgetCardWidth: 160
    readonly property int widgetGridColumns: 4
    readonly property int widgetRemoveHitSlop: -4
    readonly property int widgetRowSpacing: 8

    // Popup
    readonly property int popupContentSpacing: 10
    readonly property int popupFieldBoxHeight: 26
    readonly property int popupFieldGroupSpacing: 4
    readonly property int popupOptionButtonHeight: 24
    readonly property int popupPadding: 12
    readonly property int popupPowerCharWidth: 24
    readonly property int popupSaveButtonHeight: 28
    readonly property int popupWidthNarrow: 260
    readonly property int popupWidthWide: 360
    readonly property int textFieldInset: 6

    // Swatch
    readonly property int swatchGroupSpacing: 6
    readonly property int swatchRadius: 14
    readonly property int swatchRowSpacing: 4
    readonly property int swatchSize: 28

    // Spinner
    readonly property int spinnerDotInset: -1
    readonly property int spinnerDotRadius: 5
    readonly property int spinnerDotSize: 10
    readonly property int spinnerRotationMs: 900

    // Thumbnail
    readonly property int thumbnailBorderWidth: 3
    readonly property int thumbnailImageInset: 3
    readonly property real thumbnailInnerMarginRatio: 0.033
    readonly property int thumbnailLabelMargin: 5
    readonly property int thumbnailLabelPadding: 6
    readonly property int thumbnailRadiusBoost: 3
    readonly property int wallpaperPreviewFadeMs: 180
}
