import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RippleButton {
    id: root
    property string buttonIcon
    property alias iconSize: iconWidget.iconSize
    // Integración con buscador global de Settings
    property bool enableSettingsSearch: true
    property int settingsSearchOptionId: -1

    property real _settingsSearchBaseScale: 1.0

    SequentialAnimation {
        id: settingsSearchHighlightAnim
        running: false
        loops: 3

        PropertyAnimation {
            target: root
            property: "scale"
            to: 1.03
            duration: 90
        }
        PropertyAnimation {
            target: root
            property: "scale"
            to: 1.0
            duration: 90
        }
    }

    Layout.fillWidth: true
    implicitHeight: contentItem.implicitHeight + 8 * 2
    font.pixelSize: Appearance.font.pixelSize.small

    function _findSettingsContext() {
        var page = null;
        var sectionTitle = "";
        var groupTitle = "";
        var p = root.parent;
        while (p) {
            if (!page && p.hasOwnProperty("settingsPageIndex")) {
                page = p;
            }
            if (p.hasOwnProperty("title")) {
                if (!sectionTitle && p.hasOwnProperty("icon")) {
                    sectionTitle = p.title;
                } else if (!groupTitle && !p.hasOwnProperty("icon")) {
                    groupTitle = p.title;
                }
            }
            p = p.parent;
        }
        return { page: page, sectionTitle: sectionTitle, groupTitle: groupTitle };
    }

    function focusFromSettingsSearch() {
        var flick = null;
        var p = root.parent;
        while (p) {
            if (p.hasOwnProperty("contentY") && p.hasOwnProperty("contentHeight")) {
                flick = p;
                break;
            }
            p = p.parent;
        }

        if (flick) {
            var y = 0;
            var n = root;
            while (n && n !== flick) {
                y += n.y || 0;
                n = n.parent;
            }
            var maxY = Math.max(0, flick.contentHeight - flick.height);
            var target = Math.max(0, Math.min(y - 60, maxY));
            flick.contentY = target;
        }
        root.forceActiveFocus();
        settingsSearchHighlightAnim.stop();
        root.scale = _settingsSearchBaseScale;
        settingsSearchHighlightAnim.start();
    }

    Component.onCompleted: {
        if (!enableSettingsSearch)
            return;
        if (typeof SettingsSearchRegistry === "undefined")
            return;

        var ctx = _findSettingsContext();
        var page = ctx.page;
        var sectionTitle = ctx.sectionTitle;
        var label = root.text || ctx.groupTitle || sectionTitle;

        settingsSearchOptionId = SettingsSearchRegistry.registerOption({
            control: root,
            pageIndex: page && page.settingsPageIndex !== undefined ? page.settingsPageIndex : -1,
            pageName: page && page.settingsPageName ? page.settingsPageName : "",
            section: sectionTitle,
            label: label,
            description: "",
            keywords: []
        });
    }

    Component.onDestruction: {
        if (typeof SettingsSearchRegistry !== "undefined") {
            SettingsSearchRegistry.unregisterControl(root);
        }
    }

    onClicked: checked = !checked

    contentItem: RowLayout {
        spacing: 10
        OptionalMaterialSymbol {
            id: iconWidget
            icon: root.buttonIcon
            opacity: root.enabled ? 1 : 0.4
            iconSize: Appearance.font.pixelSize.larger
        }
        StyledText {
            id: labelWidget
            Layout.fillWidth: true
            text: root.text
            font: root.font
            color: Appearance.colors.colOnSecondaryContainer
            opacity: root.enabled ? 1 : 0.4
        }
        StyledSwitch {
            id: switchWidget
            down: root.down
            scale: 0.6
            Layout.fillWidth: false
            checked: root.checked
            onClicked: root.clicked()
        }
    }
}

