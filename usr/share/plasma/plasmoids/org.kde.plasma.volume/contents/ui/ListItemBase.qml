/*
    SPDX-FileCopyrightText: 2014-2015 Harald Sitter <sitter@kde.org>
    SPDX-FileCopyrightText: 2019 Sefa Eyeoglu <contact@scrumplex.net>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick 2.4
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

import org.kde.kquickcontrolsaddons 2.0
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.private.volume 0.1

import "../code/icon.js" as Icon

PC3.ItemDelegate {
    id: item

    required property var model
    property alias label: defaultButton.text
    property alias draggable: dragMouseArea.enabled
    property alias iconSource: clientIcon.source
    property alias iconUsesPlasmaTheme: clientIcon.usesPlasmaTheme
    // TODO: convert to a proper enum?
    property string /* "sink" | "sink-input" | "source" | "source-output" */ type
    property string fullNameToShowOnHover: ""

    highlighted: dropArea.containsDrag
    background.visible: highlighted
    opacity: (plasmoid.rootItem.draggedStream && plasmoid.rootItem.draggedStream.deviceIndex === item.model.Index) ? 0.3 : 1.0

    ListView.delayRemove: clientIcon.Drag.active

    contentItem: RowLayout {
        id: controlsRow
        spacing: item.spacing

        PlasmaCore.IconItem {
            id: clientIcon
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            implicitHeight: PlasmaCore.Units.iconSizes.medium
            implicitWidth: implicitHeight
            source: "unknown"
            visible: item.type === "sink-input" || item.type === "source-output"

            onSourceChanged: {
                if (!valid && source !== "unknown") {
                    source = "unknown";
                }
            }

            PlasmaCore.IconItem {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }
                implicitHeight: PlasmaCore.Units.iconSizes.small
                implicitWidth: implicitHeight
                source: item.type === "sink-input" || item.type === "source-output" ? "emblem-pause" : ""
                visible: valid && item.model.Corked

                PC3.ToolTip.visible: visible && dragMouseArea.containsMouse
                PC3.ToolTip.text: item.type === "source-output"
                    ? i18n("Currently not recording")
                    : i18n("Currently not playing")
                PC3.ToolTip.delay: 700
            }

            MouseArea {
                id: dragMouseArea
                enabled: contextMenu.status === 3 //Closed
                anchors.fill: parent
                cursorShape: enabled ? (pressed && pressedButtons === Qt.LeftButton ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : undefined
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                hoverEnabled: true
                drag.target: clientIcon
                onClicked: if (mouse.button === Qt.MiddleButton) {
                    item.model.Muted = !item.model.Muted;
                }
                onPressed: if (mouse.button === Qt.LeftButton) {
                    clientIcon.grabToImage(result => {
                        clientIcon.Drag.imageSource = result.url;
                    });
                }
            }
            Drag.active: dragMouseArea.drag.active
            Drag.dragType: Drag.Automatic
            Drag.onDragStarted: {
                plasmoid.rootItem.draggedStream = item.model.PulseObject;
                beginMoveStream(item.type === "sink-input" ? "sink" : "source");
            }
            Drag.onDragFinished: {
                plasmoid.rootItem.draggedStream = null;
                endMoveStream();
            }
        }

        ColumnLayout {
            id: column
            spacing: 0

            RowLayout {
                Layout.minimumHeight: contextMenuButton.implicitHeight

                PC3.RadioButton {
                    id: defaultButton
                    // Maximum width of the button need to match the text. Empty area must not change the default device.
                    Layout.maximumWidth: controlsRow.width - Layout.leftMargin - Layout.rightMargin
                                            - (contextMenuButton.visible ? contextMenuButton.implicitWidth + PlasmaCore.Units.smallSpacing * 2 : 0)
                    Layout.leftMargin: LayoutMirroring.enabled ? 0 : Math.round((muteButton.width - defaultButton.indicator.width) / 2)
                    Layout.rightMargin: LayoutMirroring.enabled ? Math.round((muteButton.width - defaultButton.indicator.width) / 2) : 0
                    spacing: PlasmaCore.Units.smallSpacing + Math.round((muteButton.width - defaultButton.indicator.width) / 2)
                    checked: item.model.PulseObject.hasOwnProperty("default") ? item.model.PulseObject.default : false
                    visible: (item.type === "sink" || item.type === "source") && item.ListView.view.count > 1
                    onClicked: item.model.PulseObject.default = true;
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: !defaultButton.visible

                    // User-friendly name
                    PC3.Label {
                        Layout.fillWidth: !longDescription.visible
                        text: defaultButton.text
                        elide: Text.ElideRight

                        MouseArea {
                            id: labelHoverHandler

                            // Only want to handle hover for the width of
                            // the actual text item itself
                            anchors.left: parent.left
                            anchors.top: parent.top
                            width: parent.contentWidth
                            height: parent.contentHeight

                            enabled: item.fullNameToShowOnHover.length > 0
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                    // Possibly not user-friendly description; only show on hover
                    PC3.Label {
                        id: longDescription

                        Layout.fillWidth: true
                        visible: opacity > 0
                        opacity: labelHoverHandler.containsMouse ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: PlasmaCore.Units.shortDuration
                                easing.type: Easing.InOutQuad
                            }
                        }

                        // Not a word puzzle because this is not a translated string
                        text: "(" + item.fullNameToShowOnHover + ")"
                        elide: Text.ElideRight
                    }
                }

                Item {
                    Layout.fillWidth: true
                    visible: contextMenuButton.visible
                }

                SmallToolButton {
                    id: contextMenuButton
                    icon.name: "application-menu"
                    checked: contextMenu.visible && contextMenu.visualParent === this
                    onPressed: {
                        contextMenu.visualParent = this;
                        contextMenu.openRelative();
                    }
                    visible: contextMenu.hasContent

                    PC3.ToolTip.visible: hovered
                    PC3.ToolTip.text: i18n("Show additional options for %1", defaultButton.text)
                    PC3.ToolTip.delay: 700
                }
            }

            RowLayout {
                SmallToolButton {
                    id: muteButton
                    readonly property bool isPlayback: item.type.startsWith("sink")
                    icon.name: Icon.name(item.model.Volume, item.model.Muted, isPlayback ? "audio-volume" : "microphone-sensitivity")
                    onClicked: item.model.Muted = !item.model.Muted
                    checked: item.model.Muted

                    PC3.ToolTip.visible: hovered
                    PC3.ToolTip.text: item.model.Muted ? i18n("Unmute %1", defaultButton.text) : i18n("Mute %1", defaultButton.text)
                    PC3.ToolTip.delay: 700
                }

                PC3.Slider {
                    id: slider

                    // Helper properties to allow async slider updates.
                    // While we are sliding we must not react to value updates
                    // as otherwise we can easily end up in a loop where value
                    // changes trigger volume changes trigger value changes.
                    property int volume: item.model.Volume
                    property bool ignoreValueChange: true
                    readonly property bool forceRaiseMaxVolume: (raiseMaximumVolumeCheckbox.checked && (item.type === "sink" || item.type === "source"))
                                                                || volume >= PulseAudio.NormalVolume * 1.01

                    Layout.fillWidth: true
                    from: PulseAudio.MinimalVolume
                    to: forceRaiseMaxVolume ? PulseAudio.MaximalVolume : PulseAudio.NormalVolume
                    stepSize: to / (to / PulseAudio.NormalVolume * 100.0)
                    visible: item.model.HasVolume
                    enabled: item.model.VolumeWritable
                    opacity: item.model.Muted ? 0.5 : 1

                    Accessible.name: i18nc("Accessibility data on volume slider", "Adjust volume for %1", defaultButton.text)

                    // Prevents the groove from showing through the handle
                    layer.enabled: opacity < 1

                    background: PlasmaCore.FrameSvgItem {
                        imagePath: "widgets/slider"
                        prefix: "groove"
                        width: parent.availableWidth
                        height: margins.top + margins.bottom
                        anchors.centerIn: parent
                        scale: parent.mirrored ? -1 : 1

                        PlasmaCore.FrameSvgItem {
                            imagePath: "widgets/slider"
                            prefix: "groove-highlight"
                            width: slider.visualPosition * slider.availableWidth
                            height: parent.height
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            scale: parent.mirrored ? -1 : 1
                        }

                        PlasmaCore.FrameSvgItem {
                            imagePath: "widgets/slider"
                            prefix: "groove-highlight"
                            anchors.left: parent.left
                            y: (parent.height - height) / 2
                            width: Math.max(margins.left + margins.right, slider.handle.x * meter.volume)
                            height: Math.max(margins.top + margins.bottom, parent.height)
                            opacity: meter.available && (meter.volume > 0 || animation.running)
                            status: PlasmaCore.FrameSvgItem.Selected
                            clip: true // prevents a visual glitch, BUG 434927
                            VolumeMonitor {
                                id: meter
                                target: slider.visible && item.model.PulseObject ? item.model.PulseObject : null
                            }
                            Behavior on width {
                                NumberAnimation  {
                                    id: animation
                                    duration: PlasmaCore.Units.shortDuration
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }

                    Component.onCompleted: {
                        ignoreValueChange = false;
                    }

                    onVolumeChanged: {
                        var oldIgnoreValueChange = ignoreValueChange;
                        ignoreValueChange = true;
                        value = item.model.Volume;
                        ignoreValueChange = oldIgnoreValueChange;
                    }

                    onValueChanged: {
                        if (!ignoreValueChange) {
                            item.model.Volume = value;
                            item.model.Muted = value === 0;

                            if (!pressed) {
                                updateTimer.restart();
                            }
                        }
                    }

                    onPressedChanged: {
                        if (!pressed) {
                            // Make sure to sync the volume once the button was
                            // released.
                            // Otherwise it might be that the slider is at v10
                            // whereas PA rejected the volume change and is
                            // still at v15 (e.g.).
                            updateTimer.restart();

                            if (type === "sink") {
                                playFeedback(item.model.Index);
                            }
                        }
                    }

                    Timer {
                        id: updateTimer
                        interval: 200
                        onTriggered: slider.value = item.model.Volume
                    }
                }
                PC3.Label {
                    id: percentText
                    readonly property real value: item.model.PulseObject.volume > slider.to ? item.model.PulseObject.volume : slider.value
                    readonly property real displayValue: Math.round(value / PulseAudio.NormalVolume * 100.0)
                    Layout.alignment: Qt.AlignHCenter
                    Layout.minimumWidth: percentMetrics.advanceWidth
                    horizontalAlignment: Qt.AlignRight
                    text: i18nc("volume percentage", "%1%", displayValue)
                    // Display a subtle visual indication that the volume
                    // might be dangerously high
                    // ------------------------------------------------
                    // Keep this in sync with the copies in VolumeSlider.qml
                    // and plasma-workspace:OSDItem.qml
                    color: {
                        if (displayValue <= 100) {
                            return PlasmaCore.Theme.textColor
                        } else if (displayValue > 100 && displayValue <= 125) {
                            return PlasmaCore.Theme.neutralTextColor
                        } else {
                            return PlasmaCore.Theme.negativeTextColor
                        }
                    }
                }

                TextMetrics {
                    id: percentMetrics
                    font: percentText.font
                    text: i18nc("only used for sizing, should be widest possible string", "100%")
                }
            }
        }
    }

    MouseArea {
        z: -1
        parent: item
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.RightButton
        onPressed: {
            if (mouse.button === Qt.RightButton) {
                contextMenu.visualParent = this;
                contextMenu.open(mouse.x, mouse.y);
            }
        }
        onClicked: {
            if (mouse.button === Qt.MiddleButton) {
                item.model.Muted = !item.model.Muted;
            }
        }
    }

    DropArea {
        id: dropArea
        z: -1
        parent: item
        anchors.fill: parent
        enabled: plasmoid.rootItem.draggedStream && plasmoid.rootItem.draggedStream.deviceIndex !== item.model.Index
        onDropped: {
            plasmoid.rootItem.draggedStream.deviceIndex = item.model.Index;
        }
    }

    ListItemMenu {
        id: contextMenu
        pulseObject: model.PulseObject
        cardModel: plasmoid.rootItem.paCardModel
        itemType: {
            switch (item.type) {
            case "sink":
                return ListItemMenu.Sink;
            case "sink-input":
                return ListItemMenu.SinkInput;
            case "source":
                return ListItemMenu.Source;
            case "source-output":
                return ListItemMenu.SourceOutput;
            }
        }
        sourceModel: if (item.type.startsWith("sink")) {
            return plasmoid.rootItem.paSinkFilterModel
        }  else if (item.type.startsWith("source")) {
            return plasmoid.rootItem.paSourceFilterModel
        }
    }

    function setVolumeByPercent(targetPercent) {
        item.model.PulseObject.volume = Math.round(PulseAudio.NormalVolume * (targetPercent/100));
    }

    Keys.onPressed: {
        const k = event.key;

        if (k === Qt.Key_M) {
            muteButton.clicked();
        } else if (k >= Qt.Key_0 && k <= Qt.Key_9) {
            setVolumeByPercent((k - Qt.Key_0) * 10);
        } else if (k === Qt.Key_Return) {
            if (defaultButton.visible) {
                defaultButton.clicked();
            }
        } else if (k === Qt.Key_Menu) {
            contextMenuButton.clicked();
        } else {
            return; // don't accept the key press
        }
        event.accepted = true;
    }
}
