import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    required property var preset
    property bool isActive: preset.id === ThemeService.currentTheme
    
    signal clicked()

    // Helper to safely get color from preset
    function getColor(key, fallback) {
        if (!preset.colors) return Appearance.m3colors[key] ?? fallback
        if (preset.colors === "custom") return Config.options?.appearance?.customTheme?.[key] ?? fallback
        return preset.colors[key] ?? fallback
    }

    implicitHeight: 40

    // Card background
    Rectangle {
        id: cardBg
        anchors.fill: parent
        radius: Appearance.rounding.small
        
        color: root.isActive 
            ? ColorUtils.transparentize(Appearance.m3colors.m3primaryContainer, 0.4)
            : mouseArea.containsMouse 
                ? Appearance.colors.colLayer2Hover
                : Appearance.colors.colLayer2
        
        border.width: root.isActive ? 1.5 : 0
        border.color: Appearance.m3colors.m3primary

        Behavior on color { enabled: Appearance.animationsEnabled; ColorAnimation { duration: 100 } }
    }

    // Content
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        // Color swatches - simple overlapping circles
        Row {
            spacing: -5

            Repeater {
                model: [
                    { key: "m3primary", fallback: "#6366f1" },
                    { key: "m3secondary", fallback: "#818cf8" },
                    { key: "m3background", fallback: "#0f0f23" }
                ]

                Rectangle {
                    required property var modelData
                    required property int index
                    
                    width: 18
                    height: 18
                    radius: 9
                    color: root.getColor(modelData.key, modelData.fallback)
                    border.width: 1.5
                    border.color: Qt.rgba(0, 0, 0, 0.25)
                    z: 3 - index
                }
            }
        }

        // Theme name
        StyledText {
            Layout.fillWidth: true
            text: preset.name
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: root.isActive ? Font.DemiBold : Font.Normal
            color: root.isActive 
                ? Appearance.m3colors.m3onPrimaryContainer 
                : Appearance.colors.colOnLayer2
            elide: Text.ElideRight
        }

        // Active check
        MaterialSymbol {
            visible: root.isActive
            text: "check"
            iconSize: 16
            color: Appearance.m3colors.m3primary
        }
    }

    // Interaction
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    // Tooltip
    StyledToolTip {
        text: preset.description ?? ""
        visible: mouseArea.containsMouse && (preset.description ?? "").length > 0
        delay: 400
    }
}
