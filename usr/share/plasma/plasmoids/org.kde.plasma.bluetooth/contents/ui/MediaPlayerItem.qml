/*
    SPDX-FileCopyrightText: 2015 David Rosca <nowrep@gmail.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick 2.2
import QtQuick.Layouts 1.1
import org.kde.bluezqt 1.0 as BluezQt
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3

ColumnLayout {
    id: mediaPlayer

    spacing: 0

    PlasmaComponents3.Label {
        id: trackTitleLabel
        Layout.fillWidth: true
        elide: Text.ElideRight
        font.weight: MediaPlayer && MediaPlayer.track.title ? Font.DemiBold : Font.Normal
        font.italic: MediaPlayer && MediaPlayer.status === BluezQt.MediaPlayer.Playing
        font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
        font.family: PlasmaCore.Theme.smallestFont.family
        opacity: 0.6
        text: trackTitleText()
        textFormat: Text.PlainText
        visible: text.length
    }

    PlasmaComponents3.Label {
        id: trackArtistLabel
        Layout.fillWidth: true
        elide: Text.ElideRight
        font: PlasmaCore.Theme.smallestFont
        opacity: 0.6
        text: MediaPlayer ? MediaPlayer.track.artist : ""
        textFormat: Text.PlainText
        visible: text.length
    }

    PlasmaComponents3.Label {
        id: trackAlbumLabel
        Layout.fillWidth: true
        elide: Text.ElideRight
        font: PlasmaCore.Theme.smallestFont
        opacity: 0.6
        text: MediaPlayer ? MediaPlayer.track.album : ""
        textFormat: Text.PlainText
        visible: text.length
    }

    RowLayout {
        spacing: 0

        PlasmaComponents3.ToolButton {
            id: previousButton
            icon.name: "media-skip-backward"

            onClicked: MediaPlayer.previous()
        }

        PlasmaComponents3.ToolButton {
            id: playPauseButton
            icon.name: playPauseButtonIcon()

            onClicked: playPauseButtonClicked()
        }

        PlasmaComponents3.ToolButton {
            id: stopButton
            icon.name: "media-playback-stop"
            enabled: MediaPlayer && MediaPlayer.status !== BluezQt.MediaPlayer.Stopped

            onClicked: MediaPlayer.stop()
        }

        PlasmaComponents3.ToolButton {
            id: nextButton
            icon.name: "media-skip-forward"

            onClicked: MediaPlayer.next()
        }
    }

    function trackTitleText()
    {
        if (!MediaPlayer) {
            return "";
        }

        var play = "\u25B6";

        if (MediaPlayer.status === BluezQt.MediaPlayer.Playing) {
            return "%1 %2".arg(play).arg(MediaPlayer.track.title);
        }
        return MediaPlayer.track.title;
    }

    function playPauseButtonIcon()
    {
        if (!MediaPlayer) {
            return "";
        }

        if (MediaPlayer.status !== BluezQt.MediaPlayer.Playing) {
            return "media-playback-start";
        } else {
            return "media-playback-pause";
        }
    }

    function playPauseButtonClicked()
    {
        if (MediaPlayer.status !== BluezQt.MediaPlayer.Playing) {
            MediaPlayer.play()
        } else {
            MediaPlayer.pause()
        }
    }
}
