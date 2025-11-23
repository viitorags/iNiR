import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property int margin: 10

    // When this widget gets focus (from BottomWidgetGroup.focusActiveItem),
    // move focus to the internal text area on the next event loop tick.
    onFocusChanged: (focus) => {
        if (focus) {
            Qt.callLater(() => textArea.forceActiveFocus())
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.margin
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Notepad")
                font.pixelSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer1
            }

            StyledText {
                text: textArea.text.length > 0
                      ? Translation.tr("%1 chars").arg(textArea.text.length)
                      : Translation.tr("Empty")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                opacity: 0.7
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            TextArea {
                id: textArea
                anchors.fill: parent
                anchors.margins: 8
                wrapMode: TextArea.Wrap
                color: Appearance.colors.colOnLayer0
                placeholderText: Translation.tr("Write your notes here...")
                placeholderTextColor: Appearance.m3colors.m3outline
                text: Notepad.text
                selectByMouse: true
                activeFocusOnTab: true

                Keys.onPressed: (event) => {
                    if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_S) {
                        Notepad.setTextValue(textArea.text)
                        event.accepted = true
                    }
                }

                onTextChanged: {
                    saveTimer.restart()
                }
            }
        }
    }

    Timer {
        id: saveTimer
        interval: 800
        repeat: false
        onTriggered: {
            Notepad.setTextValue(textArea.text)
        }
    }
}
