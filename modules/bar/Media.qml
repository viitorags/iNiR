import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")

    // Datos de carátula (cover art) inspirados en PlayerControl, pero simplificados para la barra
    property var artUrl: activePlayer?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: artUrl ? Qt.md5(artUrl) : ""
    property string artFilePath: artUrl && artUrl.length > 0 ? (artDownloadLocation + "/" + artFileName) : ""
    property bool downloaded: false
    property string displayedArtFilePath: downloaded && artFilePath.length > 0 ? Qt.resolvedUrl(artFilePath) : ""

    onArtFilePathChanged: {
        if (!artUrl || artUrl.length === 0) {
            downloaded = false;
            return;
        }
        coverArtDownloader.targetFile = artUrl;
        coverArtDownloader.artFilePath = artFilePath;
        downloaded = false;
        coverArtDownloader.running = true;
    }

    Layout.fillHeight: true
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: Appearance.sizes.barHeight

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    Process { // Descarga ligera de carátula a caché
        id: coverArtDownloader
        property string targetFile: artUrl
        property string artFilePath: root.artFilePath
        command: [
            "bash",
            "-c",
            "[ -f '" + artFilePath + "' ] || curl -sSL '" + targetFile + "' -o '" + artFilePath + "'"
        ]
        onExited: (exitCode, exitStatus) => {
            downloaded = (exitCode === 0) && artFilePath.length > 0;
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: (event) => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                activePlayer.next();
            } else if (event.button === Qt.LeftButton) {
                GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
            }
        }
    }

    RowLayout { // Real content
        id: rowLayout

        spacing: 4
        anchors.fill: parent

        ClippedFilledCircularProgress {
            id: mediaCircProg
            Layout.alignment: Qt.AlignVCenter
            lineWidth: Appearance.rounding.unsharpen
            value: (activePlayer && activePlayer.length > 0) ? (activePlayer.position / activePlayer.length) : 0
            implicitSize: 22
            colPrimary: Appearance.colors.colOnSecondaryContainer
            enableAnimation: activePlayer?.playbackState === MprisPlaybackState.Playing

            Item {
                anchors.centerIn: parent
                width: mediaCircProg.implicitSize
                height: mediaCircProg.implicitSize

                StyledImage { // Carátula actual en miniatura
                    id: coverImage
                    anchors.fill: parent
                    visible: root.displayedArtFilePath !== ""
                    source: root.displayedArtFilePath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true
                }

                MaterialSymbol { // Fallback cuando no hay carátula
                    anchors.centerIn: parent
                    visible: root.displayedArtFilePath === ""
                    fill: 1
                    text: activePlayer?.isPlaying ? "pause" : "music_note"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.m3colors.m3onSecondaryContainer
                }
            }
        }

        StyledText {
            visible: Config.options.bar.verbose
            width: rowLayout.width - (CircularProgress.size + rowLayout.spacing * 2)
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true // Ensures the text takes up available space
            Layout.rightMargin: rowLayout.spacing
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight // Truncates the text on the right
            color: Appearance.colors.colOnLayer1
            text: `${cleanedTitle}${activePlayer?.trackArtist ? ' • ' + activePlayer.trackArtist : ''}`
        }

    }

}
