import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true
    settingsPageIndex: 2
    settingsPageName: Translation.tr("Bar")

    ContentSection {
        icon: "notifications"
        title: Translation.tr("Notifications")
        ConfigSwitch {
            buttonIcon: "counter_2"
            text: Translation.tr("Unread indicator: show count")
            checked: Config.options.bar.indicators.notifications.showUnreadCount
            onCheckedChanged: {
                Config.options.bar.indicators.notifications.showUnreadCount = checked;
            }
        }
    }

    ContentSection {
        icon: "widgets"
        title: Translation.tr("Bar modules")
        // Edge modules: simple toggles
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "side_navigation"
                text: Translation.tr("Left sidebar button")
                checked: Config.options.bar.modules.leftSidebarButton
                onCheckedChanged: {
                    Config.options.bar.modules.leftSidebarButton = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "window"
                text: Translation.tr("Active window title")
                checked: Config.options.bar.modules.activeWindow
                onCheckedChanged: {
                    Config.options.bar.modules.activeWindow = checked;
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "call_to_action"
                text: Translation.tr("Right sidebar button")
                checked: Config.options.bar.modules.rightSidebarButton
                onCheckedChanged: {
                    Config.options.bar.modules.rightSidebarButton = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "shelf_auto_hide"
                text: Translation.tr("System tray")
                checked: Config.options.bar.modules.sysTray
                onCheckedChanged: {
                    Config.options.bar.modules.sysTray = checked;
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "cloud"
            text: Translation.tr("Weather")
            checked: Config.options.bar.modules.weather
            onCheckedChanged: {
                Config.options.bar.modules.weather = checked;
            }
        }

        ContentSubsection {
            id: edgeModulesLayout
            title: Translation.tr("Edge modules layout")
            tooltip: Translation.tr("Reorder the modules on the left and right sides of the bar.")

            property var leftIds: [
                "leftSidebarButton",
                "activeWindow"
            ]

            property var rightIds: [
                "rightSidebarButton",
                "sysTray",
                "weather"
            ]

            property var edgeMeta: ({
                "leftSidebarButton": {
                    "title": Translation.tr("Left sidebar button"),
                    "icon": "side_navigation"
                },
                "activeWindow": {
                    "title": Translation.tr("Active window title"),
                    "icon": "window"
                },
                "rightSidebarButton": {
                    "title": Translation.tr("Right sidebar button"),
                    "icon": "call_to_action"
                },
                "sysTray": {
                    "title": Translation.tr("System tray"),
                    "icon": "shelf_auto_hide"
                },
                "weather": {
                    "title": Translation.tr("Weather"),
                    "icon": "cloud"
                }
            })

            function sanitizedOrderFor(side) {
                const fallback = side === "left" ? leftIds : rightIds;
                const layoutObj = Config.options?.bar?.edgeModulesLayout;
                let order = [];
                if (side === "left")
                    order = (layoutObj?.leftOrder || []).slice();
                else
                    order = (layoutObj?.rightOrder || []).slice();

                if (order.length === 0)
                    return fallback.slice();

                const cleaned = [];
                for (let i = 0; i < order.length; ++i) {
                    const id = order[i];
                    if (fallback.indexOf(id) !== -1 && cleaned.indexOf(id) === -1)
                        cleaned.push(id);
                }
                for (let j = 0; j < fallback.length; ++j) {
                    const fid = fallback[j];
                    if (cleaned.indexOf(fid) === -1)
                        cleaned.push(fid);
                }
                return cleaned;
            }

            ListModel { id: leftEdgeModel }
            ListModel { id: rightEdgeModel }

            function reloadEdgeModelsFromConfig() {
                const leftOrder = sanitizedOrderFor("left");
                const rightOrder = sanitizedOrderFor("right");

                leftEdgeModel.clear();
                for (let i = 0; i < leftOrder.length; ++i)
                    leftEdgeModel.append({ moduleId: leftOrder[i] });

                rightEdgeModel.clear();
                for (let j = 0; j < rightOrder.length; ++j)
                    rightEdgeModel.append({ moduleId: rightOrder[j] });
            }

            Component.onCompleted: reloadEdgeModelsFromConfig()

            function commitEdgeModelsToConfig() {
                const leftOrder = [];
                for (let i = 0; i < leftEdgeModel.count; ++i)
                    leftOrder.push(leftEdgeModel.get(i).moduleId);

                const rightOrder = [];
                for (let j = 0; j < rightEdgeModel.count; ++j)
                    rightOrder.push(rightEdgeModel.get(j).moduleId);

                Config.options.bar.edgeModulesLayout.leftOrder = leftOrder;
                Config.options.bar.edgeModulesLayout.rightOrder = rightOrder;
            }

            Component {
                id: edgeModuleChipDelegate
                Item {
                    id: chipRoot
                    required property int index
                    required property string moduleId

                    width: chipBackground.implicitWidth + 4
                    height: chipBackground.implicitHeight + 4

                    Drag.active: dragArea.dragging
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2
                    Drag.source: chipRoot

                    Rectangle {
                        id: chipBackground
                        anchors.centerIn: parent
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colLayer1
                        border.width: 1
                        border.color: Appearance.colors.colOutlineVariant
                        implicitHeight: 32
                        implicitWidth: 120

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            MaterialSymbol {
                                text: edgeModulesLayout.edgeMeta[moduleId].icon
                                iconSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: edgeModulesLayout.edgeMeta[moduleId].title
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }

                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        hoverEnabled: true
                        property bool dragging: false

                        onPressed: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                dragging = true;
                            }
                        }

                        onReleased: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                if (dragging)
                                    chipRoot.Drag.drop();
                                dragging = false;
                            }
                        }

                        onCanceled: {
                            dragging = false;
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: Translation.tr("Drag the chips to reorder the modules on each side of the bar.")
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        StyledText {
                            text: Translation.tr("Left side")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }

                        ListView {
                            id: leftEdgeView
                            Layout.fillWidth: true
                            Layout.preferredHeight: contentHeight
                            clip: true
                            model: leftEdgeModel
                            interactive: false
                            orientation: ListView.Horizontal
                            boundsBehavior: Flickable.StopAtBounds
                            spacing: 8

                            delegate: Item {
                                id: leftChipRoot
                                required property int index
                                required property string moduleId

                                width: chipLoader.implicitWidth
                                height: chipLoader.implicitHeight

                                Loader {
                                    id: chipLoader
                                    anchors.centerIn: parent
                                    sourceComponent: edgeModuleChipDelegate
                                    onLoaded: {
                                        item.index = leftChipRoot.index;
                                        item.moduleId = leftChipRoot.moduleId;
                                    }
                                }

                                DropArea {
                                    anchors.fill: parent
                                    onDropped: drop => {
                                        const src = drop.source;
                                        if (!src || src.index === undefined)
                                            return;
                                        const from = src.index;
                                        const to = leftChipRoot.index;
                                        if (from === to)
                                            return;
                                        leftEdgeModel.move(from, to, 1);
                                        edgeModulesLayout.commitEdgeModelsToConfig();
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        StyledText {
                            text: Translation.tr("Right side")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }

                        ListView {
                            id: rightEdgeView
                            Layout.fillWidth: true
                            Layout.preferredHeight: contentHeight
                            clip: true
                            model: rightEdgeModel
                            interactive: false
                            orientation: ListView.Horizontal
                            boundsBehavior: Flickable.StopAtBounds
                            spacing: 8

                            delegate: Item {
                                id: rightChipRoot
                                required property int index
                                required property string moduleId

                                width: chipLoader.implicitWidth
                                height: chipLoader.implicitHeight

                                Loader {
                                    id: chipLoader
                                    anchors.centerIn: parent
                                    sourceComponent: edgeModuleChipDelegate
                                    onLoaded: {
                                        item.index = rightChipRoot.index;
                                        item.moduleId = rightChipRoot.moduleId;
                                    }
                                }

                                DropArea {
                                    anchors.fill: parent
                                    onDropped: drop => {
                                        const src = drop.source;
                                        if (!src || src.index === undefined)
                                            return;
                                        const from = src.index;
                                        const to = rightChipRoot.index;
                                        if (from === to)
                                            return;
                                        rightEdgeModel.move(from, to, 1);
                                        edgeModulesLayout.commitEdgeModelsToConfig();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        ContentSubsection {
            id: centralModulesLayout
            title: Translation.tr("Central modules layout")
            tooltip: Translation.tr("Drag to reorder modules and choose which section they appear in: Start, Center or End.")

            // Módulos centrales de la barra y metadatos para el editor de layout
            property var centralModuleIds: [
                "resources",
                "media",
                "workspaces",
                "clock",
                "utilButtons",
                "battery"
            ]

            property var centralModulesMeta: ({
                "resources": {
                    "title": Translation.tr("Resources widget"),
                    "description": Translation.tr("Shows CPU, memory and other system stats."),
                    "icon": "speed"
                },
                "media": {
                    "title": Translation.tr("Media widget"),
                    "description": Translation.tr("Shows currently playing media with controls."),
                    "icon": "music_note"
                },
                "workspaces": {
                    "title": Translation.tr("Workspaces widget"),
                    "description": Translation.tr("Shows current and available workspaces."),
                    "icon": "workspaces"
                },
                "clock": {
                    "title": Translation.tr("Clock widget"),
                    "description": Translation.tr("Shows the current time and date."),
                    "icon": "schedule"
                },
                "utilButtons": {
                    "title": Translation.tr("Utility buttons"),
                    "description": Translation.tr("Shows quick action buttons for snip, color picker and more."),
                    "icon": "widgets"
                },
                "battery": {
                    "title": Translation.tr("Battery indicator"),
                    "description": Translation.tr("Shows laptop battery charge and status."),
                    "icon": "battery_horiz_075"
                }
            })

            function sanitizedOrder() {
                const fallback = centralModuleIds;
                let order = (Config.options?.bar?.modulesLayout?.order || []).slice();
                if (order.length === 0) {
                    return fallback.slice();
                }
                const cleaned = [];
                for (let i = 0; i < order.length; ++i) {
                    const id = order[i];
                    if (fallback.indexOf(id) !== -1 && cleaned.indexOf(id) === -1)
                        cleaned.push(id);
                }
                for (let j = 0; j < fallback.length; ++j) {
                    const fid = fallback[j];
                    if (cleaned.indexOf(fid) === -1)
                        cleaned.push(fid);
                }
                return cleaned;
            }

            ListModel {
                id: centralModulesModel
            }

            function reloadModelFromConfig() {
                const order = sanitizedOrder();
                centralModulesModel.clear();
                for (let i = 0; i < order.length; ++i) {
                    centralModulesModel.append({ moduleId: order[i] });
                }
            }

            Component.onCompleted: reloadModelFromConfig()

            function commitModelToConfig() {
                const order = [];
                for (let i = 0; i < centralModulesModel.count; ++i) {
                    order.push(centralModulesModel.get(i).moduleId);
                }
                Config.options.bar.modulesLayout.order = order;
            }

            function handleZoneDrop(drop, zone) {
                const src = drop.source;
                if (!src || !src.moduleId)
                    return;
                if (Config.options.bar.modulesPlacement[src.moduleId] === zone)
                    return;
                Config.options.bar.modulesPlacement[src.moduleId] = zone;
            }

            Component {
                id: centralModuleChipDelegate
                Item {
                    id: chipRoot
                    property int index
                    property string moduleId
                    property string zone: "center"

                    readonly property string currentZone: (Config.options.bar.modulesPlacement[moduleId] || "center")
                    visible: currentZone === zone

                    Layout.fillWidth: true
                    height: chipBackground.implicitHeight + 4

                    Drag.active: dragArea.dragging
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2
                    Drag.source: chipRoot

                    Rectangle {
                        id: chipBackground
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colLayer1
                        border.width: 1
                        border.color: Appearance.colors.colOutlineVariant
                        implicitHeight: 32

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            MaterialSymbol {
                                text: centralModulesLayout.centralModulesMeta[moduleId].icon
                                iconSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: centralModulesLayout.centralModulesMeta[moduleId].title
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }

                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        hoverEnabled: true
                        property bool dragging: false

                        onPressed: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                dragging = true;
                            }
                        }

                        onReleased: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                if (dragging)
                                    chipRoot.Drag.drop();
                                dragging = false;
                            }
                        }

                        onCanceled: {
                            dragging = false;
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: Translation.tr("Drag the rows to change the global order of central modules. Use the Start/Center/End controls in each row to choose their island.")
                }

                ListView {
                    id: centralModulesView
                    Layout.fillWidth: true
                    Layout.preferredHeight: contentHeight
                    clip: true
                    model: centralModulesModel
                    interactive: true
                    orientation: ListView.Vertical
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: 8

                    delegate: Item {
                        id: rowRoot
                        required property int index
                        required property string moduleId

                        // Drag & drop (usa botón central para no interferir con los clicks normales)
                        Drag.active: dragArea.dragging
                        Drag.hotSpot.x: width / 2
                        Drag.hotSpot.y: height / 2
                        Drag.source: rowRoot

                        width: centralModulesView.width
                        height: rowContent.implicitHeight

                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            acceptedButtons: Qt.MiddleButton
                            cursorShape: Qt.OpenHandCursor
                            property bool dragging: false

                            onPressed: mouse => {
                                if (mouse.button === Qt.MiddleButton) {
                                    dragging = true;
                                    cursorShape = Qt.ClosedHandCursor;
                                }
                            }

                            onReleased: mouse => {
                                if (mouse.button === Qt.MiddleButton) {
                                    if (dragging)
                                        rowRoot.Drag.drop();
                                    dragging = false;
                                    cursorShape = Qt.OpenHandCursor;
                                }
                            }

                            onCanceled: {
                                dragging = false;
                                cursorShape = Qt.OpenHandCursor;
                            }
                        }

                        DropArea {
                            anchors.fill: parent
                            onDropped: drop => {
                                const src = drop.source;
                                if (!src || src.index === undefined)
                                    return;
                                const from = src.index;
                                const to = rowRoot.index;
                                if (from === to)
                                    return;
                                centralModulesModel.move(from, to, 1);
                                centralModulesLayout.commitModelToConfig();
                            }
                        }

                        ColumnLayout {
                            id: rowContent
                            anchors.left: parent.left
                            anchors.right: parent.right

                            ConfigRow {
                                uniform: true

                                ContentSubsection {
                                    title: centralModulesLayout.centralModulesMeta[moduleId].title
                                    Layout.fillWidth: true
                                    StyledText {
                                        Layout.fillWidth: true
                                        color: Appearance.colors.colSubtext
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        text: centralModulesLayout.centralModulesMeta[moduleId].description
                                    }
                                }

                                ConfigSelectionArray {
                                    Layout.preferredWidth: 260
                                    currentValue: Config.options.bar.modulesPlacement[moduleId] || "center"
                                    onSelected: newValue => {
                                        Config.options.bar.modulesPlacement[moduleId] = newValue;
                                    }
                                    options: [
                                        {
                                            displayName: Translation.tr("Start"),
                                            icon: "align_horizontal_left",
                                            value: "start"
                                        },
                                        {
                                            displayName: Translation.tr("Center"),
                                            icon: "align_horizontal_center",
                                            value: "center"
                                        },
                                        {
                                            displayName: Translation.tr("End"),
                                            icon: "align_horizontal_right",
                                            value: "end"
                                        }
                                    ]
                                }

                                ConfigSwitch {
                                    buttonIcon: centralModulesLayout.centralModulesMeta[moduleId].icon
                                    text: Translation.tr("Enabled")
                                    checked: Config.options.bar.modules[moduleId]
                                    onCheckedChanged: {
                                        Config.options.bar.modules[moduleId] = checked;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "spoke"
        title: Translation.tr("Positioning")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Top"),
                            icon: "arrow_upward",
                            value: 0 // bottom: false, vertical: false
                        },
                        {
                            displayName: Translation.tr("Left"),
                            icon: "arrow_back",
                            value: 2 // bottom: false, vertical: true
                        },
                        {
                            displayName: Translation.tr("Bottom"),
                            icon: "arrow_downward",
                            value: 1 // bottom: true, vertical: false
                        },
                        {
                            displayName: Translation.tr("Right"),
                            icon: "arrow_forward",
                            value: 3 // bottom: true, vertical: true
                        }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Automatically hide")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.autoHide.enable
                    onSelected: newValue => {
                        Config.options.bar.autoHide.enable = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: true
                        }
                    ]
                }
            }
        }

        ConfigRow {
            
            ContentSubsection {
                title: Translation.tr("Corner style")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Hug"),
                            icon: "line_curve",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Float"),
                            icon: "page_header",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "toolbar",
                            value: 2
                        }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Group style")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.borderless
                    onSelected: newValue => {
                        Config.options.bar.borderless = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Pills"),
                            icon: "location_chip",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Line-separated"),
                            icon: "split_scene",
                            value: true
                        }
                    ]
                }
            }
        }
    }

    ContentSection {
        icon: "shelf_auto_hide"
        title: Translation.tr("Tray")

        ConfigSwitch {
            buttonIcon: "keep"
            text: Translation.tr('Make icons pinned by default')
            checked: Config.options.bar.tray.invertPinnedItems
            onCheckedChanged: {
                Config.options.bar.tray.invertPinnedItems = checked;
            }
        }
        
        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr('Tint icons')
            checked: Config.options.bar.tray.monochromeIcons
            onCheckedChanged: {
                Config.options.bar.tray.monochromeIcons = checked;
            }
        }
    }

    ContentSection {
        icon: "widgets"
        title: Translation.tr("Utility buttons")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "content_cut"
                text: Translation.tr("Screen snip")
                checked: Config.options.bar.utilButtons.showScreenSnip
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenSnip = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "colorize"
                text: Translation.tr("Color picker")
                checked: Config.options.bar.utilButtons.showColorPicker
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showColorPicker = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "keyboard"
                text: Translation.tr("Keyboard toggle")
                checked: Config.options.bar.utilButtons.showKeyboardToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showKeyboardToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "mic"
                text: Translation.tr("Mic toggle")
                checked: Config.options.bar.utilButtons.showMicToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showMicToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: Translation.tr("Dark/Light toggle")
                checked: Config.options.bar.utilButtons.showDarkModeToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showDarkModeToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "speed"
                text: Translation.tr("Performance Profile toggle")
                checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showPerformanceProfileToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "videocam"
                text: Translation.tr("Record")
                checked: Config.options.bar.utilButtons.showScreenRecord
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenRecord = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "edit_note"
                text: Translation.tr("Notepad")
                checked: Config.options.bar.utilButtons.showNotepad
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showNotepad = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "cloud"
        title: Translation.tr("Weather")
        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable")
            checked: Config.options.bar.weather.enable
            onCheckedChanged: {
                Config.options.bar.weather.enable = checked;
            }
        }
    }

    ContentSection {
        icon: "workspaces"
        title: Translation.tr("Workspaces")

        ConfigSwitch {
            buttonIcon: "counter_1"
            text: Translation.tr('Always show numbers')
            checked: Config.options.bar.workspaces.alwaysShowNumbers
            onCheckedChanged: {
                Config.options.bar.workspaces.alwaysShowNumbers = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "award_star"
            text: Translation.tr('Show app icons')
            checked: Config.options.bar.workspaces.showAppIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.showAppIcons = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr('Tint app icons')
            checked: Config.options.bar.workspaces.monochromeIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.monochromeIcons = checked;
            }
        }

        ConfigSpinBox {
            icon: "view_column"
            text: Translation.tr("Workspaces shown")
            value: Config.options.bar.workspaces.shown
            from: 1
            to: 30
            stepSize: 1
            onValueChanged: {
                Config.options.bar.workspaces.shown = value;
            }
        }

        ConfigSpinBox {
            icon: "touch_long"
            text: Translation.tr("Number show delay when pressing Super (ms)")
            value: Config.options.bar.workspaces.showNumberDelay
            from: 0
            to: 1000
            stepSize: 50
            onValueChanged: {
                Config.options.bar.workspaces.showNumberDelay = value;
            }
        }

        ContentSubsection {
            title: Translation.tr("Number style")

            ConfigSelectionArray {
                currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                onSelected: newValue => {
                    Config.options.bar.workspaces.numberMap = JSON.parse(newValue)
                }
                options: [
                    {
                        displayName: Translation.tr("Normal"),
                        icon: "timer_10",
                        value: '["1","2","3","4","5","6","7","8","9","10"]'
                    },
                    {
                        displayName: Translation.tr("Japanese"),
                        icon: "square_dot",
                        value: '["一","二","三","四","五","六","七","八","九","十"]'
                    },
                    {
                        displayName: Translation.tr("Roman"),
                        icon: "account_balance",
                        value: '["I","II","III","IV","V","VI","VII","VIII","IX","X"]'
                    }
                ]
            }
        }
    }
}
