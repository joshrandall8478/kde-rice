/*
    SPDX-FileCopyrightText: 2014-2015 Harald Sitter <sitter@kde.org>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick 2.2
import QtQuick.Layouts 1.0

import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0
import org.kde.kquickcontrolsaddons 2.0 as KQCAddons

import org.kde.plasma.private.volume 0.1

import "../code/icon.js" as Icon

Item {
    id: main

    property bool volumeFeedback: Plasmoid.configuration.volumeFeedback
    property bool globalMute: Plasmoid.configuration.globalMute
    property int currentMaxVolumePercent: plasmoid.configuration.raiseMaximumVolume ? 150 : 100
    property int currentMaxVolumeValue: currentMaxVolumePercent * PulseAudio.NormalVolume / 100.00
    property int volumePercentStep: Plasmoid.configuration.volumeStep
    property string displayName: i18n("Audio Volume")
    property QtObject draggedStream: null

    property bool showVirtualDevices: Plasmoid.configuration.showVirtualDevices

    // DEFAULT_SINK_NAME in module-always-sink.c
    readonly property string dummyOutputName: "auto_null"

    Layout.minimumHeight: PlasmaCore.Units.gridUnit * 8
    Layout.minimumWidth: PlasmaCore.Units.gridUnit * 14
    Layout.preferredHeight: PlasmaCore.Units.gridUnit * 21
    Layout.preferredWidth: PlasmaCore.Units.gridUnit * 24
    Plasmoid.switchHeight: Layout.minimumHeight
    Plasmoid.switchWidth: Layout.minimumWidth

    Plasmoid.icon: paSinkModel.preferredSink && !isDummyOutput(paSinkModel.preferredSink) ? Icon.name(paSinkModel.preferredSink.volume, paSinkModel.preferredSink.muted)
                                                                                          : Icon.name(0, true)
    Plasmoid.toolTipMainText: {
        var sink = paSinkModel.preferredSink;
        if (!sink || isDummyOutput(sink)) {
            return displayName;
        }

        if (sink.muted) {
            return i18n("Audio Muted");
        } else {
            return i18n("Volume at %1%", volumePercent(sink.volume));
        }
    }
    Plasmoid.toolTipSubText: {
        if (paSinkModel.preferredSink && !isDummyOutput(paSinkModel.preferredSink)) {
            var port = paSinkModel.preferredSink.ports[paSinkModel.preferredSink.activePortIndex];
            if (port) {
                return port.description
            }

            if (paSinkModel.preferredSink.description) {
                return paSinkModel.preferredSink.description
            }

            return paSinkModel.preferredSink.name
        }
        return ""
    }

    function isDummyOutput(output) {
        return output && output.name === dummyOutputName;
    }

    function boundVolume(volume) {
        return Math.max(PulseAudio.MinimalVolume, Math.min(volume, currentMaxVolumeValue));
    }

    function volumePercent(volume) {
        return Math.round(volume / PulseAudio.NormalVolume * 100.0);
    }

    // Increment a VolumeObject (Sink or Source) by %volume.
    function changeVolumeByPercent(volumeObject, deltaPercent) {
        const oldVolume = volumeObject.volume;
        const oldPercent = volumePercent(oldVolume);
        const targetPercent = oldPercent + deltaPercent;
        const newVolume = boundVolume(Math.round(PulseAudio.NormalVolume * (targetPercent/100)));
        const newPercent = volumePercent(newVolume);
        volumeObject.muted = newPercent == 0;
        volumeObject.volume = newVolume;
        return newPercent;
    }

    // Increment the preferredSink by %volume.
    function changeSpeakerVolume(deltaPercent) {
        if (!paSinkModel.preferredSink || isDummyOutput(paSinkModel.preferredSink)) {
            return;
        }
        const newPercent = changeVolumeByPercent(paSinkModel.preferredSink, deltaPercent);
        osd.showVolume(newPercent);
        playFeedback();
    }

    function increaseVolume() {
        if (globalMute) {
            disableGlobalMute();
        }
        changeSpeakerVolume(volumePercentStep);
    }

    function decreaseVolume() {
        if (globalMute) {
            disableGlobalMute();
        }
        changeSpeakerVolume(-volumePercentStep);
    }

    function muteVolume() {
        if (!paSinkModel.preferredSink || isDummyOutput(paSinkModel.preferredSink)) {
            return;
        }
        var toMute = !paSinkModel.preferredSink.muted;
        if (toMute) {
            enableGlobalMute();
            osd.showMute(0);
        } else {
            if (globalMute) {
                disableGlobalMute();
            }
            paSinkModel.preferredSink.muted = toMute;
            osd.showMute(volumePercent(paSinkModel.preferredSink.volume));
            playFeedback();
        }
    }

    // Increment the defaultSource by %volume.
    function changeMicrophoneVolume(deltaPercent) {
        if (!paSourceModel.defaultSource) {
            return;
        }
        const newPercent = changeVolumeByPercent(paSourceModel.defaultSource, deltaPercent);
        osd.showMic(newPercent);
    }

    function increaseMicrophoneVolume() {
        changeMicrophoneVolume(volumePercentStep);
    }

    function decreaseMicrophoneVolume() {
        changeMicrophoneVolume(-volumePercentStep);
    }

    function muteMicrophone() {
        if (!paSourceModel.defaultSource) {
            return;
        }
        var toMute = !paSourceModel.defaultSource.muted;
        paSourceModel.defaultSource.muted = toMute;
        osd.showMicMute(toMute? 0 : volumePercent(paSourceModel.defaultSource.volume));
    }

    function playFeedback(sinkIndex) {
        if (!volumeFeedback) {
            return;
        }
        if (sinkIndex == undefined) {
            sinkIndex = paSinkModel.preferredSink.index;
        }
        feedback.play(sinkIndex);
    }


    function enableGlobalMute() {
        var role = paSinkModel.role("Muted");
        var rowCount = paSinkModel.rowCount();
        // List for devices that are already muted. Will use to keep muted after disable GlobalMute.
        var globalMuteDevices = [];

        for (var i = 0; i < rowCount; i++) {
            var idx = paSinkModel.index(i, 0);
            var name = paSinkModel.data(idx, paSinkModel.role("Name"));
            if (paSinkModel.data(idx, role) === false) {
                paSinkModel.setData(idx, true, role);
            } else {
                globalMuteDevices.push(name + "." + paSinkModel.data(idx, paSinkModel.role("ActivePortIndex")));
            }
        }
        // If all the devices were muted, will unmute them all with disable GlobalMute.
        plasmoid.configuration.globalMuteDevices = globalMuteDevices.length < rowCount ? globalMuteDevices : [];
        plasmoid.configuration.globalMute = true;
        globalMute = true;
    }

    function disableGlobalMute() {
        var role = paSinkModel.role("Muted");
        for (var i = 0; i < paSinkModel.rowCount(); i++) {
            var idx = paSinkModel.index(i, 0);
            var name = paSinkModel.data(idx, paSinkModel.role("Name")) + "." + paSinkModel.data(idx, paSinkModel.role("ActivePortIndex"));
            if (plasmoid.configuration.globalMuteDevices.indexOf(name) === -1) {
                paSinkModel.setData(idx, false, role);
            }
        }
        plasmoid.configuration.globalMuteDevices = [];
        plasmoid.configuration.globalMute = false;
        globalMute = false;
    }

    // Output devices
    readonly property SinkModel paSinkModel: SinkModel {
        id: paSinkModel

        property bool initalDefaultSinkIsSet: false

        onDefaultSinkChanged: {
            if (!defaultSink || !plasmoid.configuration.outputChangeOsd) {
                return;
            }

            // avoid showing a OSD on startup
            if (!initalDefaultSinkIsSet) {
                initalDefaultSinkIsSet = true;
                return;
            }

            var description = defaultSink.description;
            if (isDummyOutput(defaultSink)) {
                description = i18n("No output device");
            }

            var icon = Icon.formFactorIcon(defaultSink.formFactor);
            if (!icon) {
                // Show "muted" icon for Dummy output
                if (isDummyOutput(defaultSink)) {
                    icon = "audio-volume-muted";
                }
            }

            if (!icon) {
                icon = Icon.name(defaultSink.volume, defaultSink.muted);
            }
            osd.showText(icon, description);
        }

        onRowsInserted: {
            if (globalMute) {
                var role = paSinkModel.role("Muted");
                for (var i = 0; i < paSinkModel.rowCount(); i++) {
                    var idx = paSinkModel.index(i, 0);
                    if (paSinkModel.data(idx, role) === false) {
                        paSinkModel.setData(idx, true, role);
                    }
                }
            }
        }
    }

    // Input devices
    readonly property SourceModel paSourceModel: SourceModel { id: paSourceModel }

    // Confusingly, Sink Input is what PulseAudio calls streams that send audio to an output device
    readonly property SinkInputModel paSinkInputModel: SinkInputModel { id: paSinkInputModel }

    // Confusingly, Source Output is what PulseAudio calls streams that take audio from an input device
    readonly property SourceOutputModel paSourceOutputModel: SourceOutputModel { id: paSourceOutputModel }

    // active output devices
    readonly property PulseObjectFilterModel paSinkFilterModel: PulseObjectFilterModel {
        id: paSinkFilterModel
        sortRole: "SortByDefault"
        sortOrder: Qt.DescendingOrder
        filterOutInactiveDevices: true
        filterVirtualDevices: !main.showVirtualDevices
        sourceModel: paSinkModel
    }

    // active input devices
    readonly property PulseObjectFilterModel paSourceFilterModel: PulseObjectFilterModel {
        id: paSourceFilterModel
        sortRole: "SortByDefault"
        sortOrder: Qt.DescendingOrder
        filterOutInactiveDevices: true
        filterVirtualDevices: !main.showVirtualDevices
        sourceModel: paSourceModel
    }

    // non-virtual streams going to output devices
    readonly property PulseObjectFilterModel paSinkInputFilterModel: PulseObjectFilterModel {
        id: paSinkInputFilterModel
        filters: [ { role: "VirtualStream", value: false } ]
        sourceModel: paSinkInputModel
    }

    // non-virtual streams coming from input devices
    readonly property PulseObjectFilterModel paSourceOutputFilterModel: PulseObjectFilterModel {
        id: paSourceOutputFilterModel
        filters: [ { role: "VirtualStream", value: false } ]
        sourceModel: paSourceOutputModel
    }

    readonly property CardModel paCardModel: CardModel {
        id: paCardModel
    }

    Plasmoid.compactRepresentation:MouseArea {
        property int wheelDelta: 0
        property bool wasExpanded: false

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onPressed: {
            if (mouse.button == Qt.LeftButton) {
                wasExpanded = plasmoid.expanded;
            } else if (mouse.button == Qt.MiddleButton) {
                muteVolume();
            }
        }
        onClicked: {
            if (mouse.button == Qt.LeftButton) {
                plasmoid.expanded = !wasExpanded;
            }
        }
        onWheel: {
            var delta = wheel.angleDelta.y || wheel.angleDelta.x;
            wheelDelta += delta;
            // Magic number 120 for common "one click"
            // See: https://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
            while (wheelDelta >= 120) {
                wheelDelta -= 120;
                increaseVolume();
            }
            while (wheelDelta <= -120) {
                wheelDelta += 120;
                decreaseVolume();
            }
        }
        PlasmaCore.IconItem {
            anchors.fill: parent
            source: plasmoid.icon
            active: parent.containsMouse
            colorGroup: PlasmaCore.ColorScope.colorGroup
        }
    }

    GlobalActionCollection {
        // KGlobalAccel cannot transition from kmix to something else, so if
        // the user had a custom shortcut set for kmix those would get lost.
        // To avoid this we hijack kmix name and actions. Entirely mental but
        // best we can do to not cause annoyance for the user.
        // The display name actually is updated to whatever registered last
        // though, so as far as user visible strings go we should be fine.
        // As of 2015-07-21:
        //   componentName: kmix
        //   actions: increase_volume, decrease_volume, mute
        name: "kmix"
        displayName: main.displayName
        GlobalAction {
            objectName: "increase_volume"
            text: i18n("Increase Volume")
            shortcut: Qt.Key_VolumeUp
            onTriggered: increaseVolume()
        }
        GlobalAction {
            objectName: "decrease_volume"
            text: i18n("Decrease Volume")
            shortcut: Qt.Key_VolumeDown
            onTriggered: decreaseVolume()
        }
        GlobalAction {
            objectName: "mute"
            text: i18n("Mute")
            shortcut: Qt.Key_VolumeMute
            onTriggered: muteVolume()
        }
        GlobalAction {
            objectName: "increase_microphone_volume"
            text: i18n("Increase Microphone Volume")
            shortcut: Qt.Key_MicVolumeUp
            onTriggered: increaseMicrophoneVolume()
        }
        GlobalAction {
            objectName: "decrease_microphone_volume"
            text: i18n("Decrease Microphone Volume")
            shortcut: Qt.Key_MicVolumeDown
            onTriggered: decreaseMicrophoneVolume()
        }
        GlobalAction {
            objectName: "mic_mute"
            text: i18n("Mute Microphone")
            shortcuts: [Qt.Key_MicMute, Qt.MetaModifier | Qt.Key_VolumeMute]
            onTriggered: muteMicrophone()
        }
    }

    VolumeOSD {
        id: osd

        function showVolume(text) {
            if (!main.Plasmoid.configuration.volumeOsd)
                return
            show(text, currentMaxVolumePercent)
        }

        function showMute(text) {
            if (!main.Plasmoid.configuration.muteOsd)
                return
            show(text, currentMaxVolumePercent)
        }

        function showMic(text) {
            if (!main.Plasmoid.configuration.micOsd)
                return
            showMicrophone(text)
        }

        function showMicMute(text) {
            if (!main.Plasmoid.configuration.muteOsd)
                return
            showMicrophone(text)
        }
    }

    VolumeFeedback {
        id: feedback
    }

    PlasmaCore.Svg {
        id: lineSvg
        imagePath: "widgets/line"
    }

    Plasmoid.fullRepresentation: PlasmaExtras.Representation {
        Layout.preferredHeight: main.Layout.preferredHeight
        Layout.preferredWidth: main.Layout.preferredWidth
        collapseMarginsHint: true

        function beginMoveStream(type, stream) {
            if (type === "sink") {
                contentView.hiddenTypes = "source"
            } else if (type === "source") {
                contentView.hiddenTypes = "sink"
            }
            tabBar.setCurrentIndex(devicesTab.PC3.TabBar.index)
        }

        function endMoveStream() {
            contentView.hiddenTypes = []
            tabBar.setCurrentIndex(streamsTab.PC3.TabBar.index)
        }

        header: PlasmaExtras.PlasmoidHeading {
            // Make this toolbar's buttons align vertically with the ones above
            rightPadding: -PlasmaCore.Units.devicePixelRatio
            // Allow tabbar to touch the header's bottom border
            bottomPadding: -bottomInset

            RowLayout {
                anchors.fill: parent

                PC3.TabBar {
                    id: tabBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    currentIndex: {
                        switch (plasmoid.configuration.currentTab) {
                        case "devices":
                            return devicesTab.PC3.TabBar.index;
                        case "streams":
                            return streamsTab.PC3.TabBar.index;
                        }
                    }

                    onCurrentIndexChanged: {
                        switch (currentIndex) {
                        case devicesTab.PC3.TabBar.index:
                            plasmoid.configuration.currentTab = "devices";
                            break;
                        case streamsTab.PC3.TabBar.index:
                            plasmoid.configuration.currentTab = "streams";
                            break;
                        }
                    }

                    PC3.TabButton {
                        id: devicesTab
                        text: i18n("Devices")
                    }

                    PC3.TabButton {
                        id: streamsTab
                        text: i18n("Applications")
                    }
                }

                PC3.ToolButton {
                    id: globalMuteCheckbox

                    visible: !(plasmoid.containmentDisplayHints & PlasmaCore.Types.ContainmentDrawsPlasmoidHeading)

                    icon.name: "audio-volume-muted"
                    onClicked: {
                        if (!globalMute) {
                            enableGlobalMute();
                        } else {
                            disableGlobalMute();
                        }
                    }
                    checked: globalMute

                    Accessible.name: i18n("Force mute all playback devices")
                    PC3.ToolTip {
                        text: i18n("Force mute all playback devices")
                    }
                }

                PC3.ToolButton {
                    visible: !(plasmoid.containmentDisplayHints & PlasmaCore.Types.ContainmentDrawsPlasmoidHeading)

                    icon.name: "configure"
                    onClicked: plasmoid.action("configure").trigger()

                    Accessible.name: plasmoid.action("configure").text
                    PC3.ToolTip {
                        text: plasmoid.action("configure").text
                    }
                }
            }
        }

        // NOTE: using a StackView instead of a SwipeView partly because
        // SwipeView would never start with the correct initial view when the
        // last saved view was the streams view.
        // We also don't need to be able to swipe between views.
        contentItem: HorizontalStackView {
            id: contentView
            property var hiddenTypes: []
            initialItem: plasmoid.configuration.currentTab === "streams" ? streamsView : devicesView
            movementTransitionsEnabled: currentItem !== null
            TwoPartView {
                id: devicesView
                upperModel: paSinkFilterModel
                upperType: "sink"
                lowerModel: paSourceFilterModel
                lowerType: "source"
                iconName: "audio-volume-muted"
                placeholderText: i18n("No output or input devices found")
                upperDelegate: DeviceListItem {
                    width: ListView.view.width
                    type: devicesView.upperType
                }
                lowerDelegate: DeviceListItem {
                    width: ListView.view.width
                    type: devicesView.lowerType
                }
            }
            // NOTE: Don't unload this while dragging and dropping a stream
            // to a device or else the D&D operation will be cancelled.
            TwoPartView {
                id: streamsView
                upperModel: paSinkInputFilterModel
                upperType: "sink-input"
                lowerModel: paSourceOutputFilterModel
                lowerType: "source-output"
                iconName: "edit-none"
                placeholderText: i18n("No applications playing or recording audio")
                upperDelegate: StreamListItem {
                    width: ListView.view.width
                    type: streamsView.upperType
                    devicesModel: paSinkFilterModel
                }
                lowerDelegate: StreamListItem {
                    width: ListView.view.width
                    type: streamsView.lowerType
                    devicesModel: paSourceFilterModel
                }
            }
            Connections {
                target: tabBar
                function onCurrentIndexChanged() {
                    if (tabBar.currentItem === devicesTab) {
                        contentView.reverseTransitions = false
                        contentView.replace(devicesView)
                    } else if (tabBar.currentItem === streamsTab) {
                        contentView.reverseTransitions = true
                        contentView.replace(streamsView)
                    }
                }
            }
        }

        component TwoPartView : PC3.ScrollView {
            id: scrollView
            required property PulseObjectFilterModel upperModel
            required property string upperType
            required property Component upperDelegate
            required property PulseObjectFilterModel lowerModel
            required property string lowerType
            required property Component lowerDelegate
            property string iconName: null
            property string placeholderText: ""

             // HACK: workaround for https://bugreports.qt.io/browse/QTBUG-83890
            PC3.ScrollBar.horizontal.policy: PC3.ScrollBar.AlwaysOff

            Loader {
                parent: scrollView
                anchors.centerIn: parent
                width: parent.width -  PlasmaCore.Units.gridUnit * 4
                active: visible
                visible: scrollView.placeholderText.length > 0 && !upperSection.visible && !lowerSection.visible
                sourceComponent: PlasmaExtras.PlaceholderMessage {
                    iconName: scrollView.iconName
                    text: scrollView.placeholderText
                }
            }
            contentItem: Flickable {
                contentHeight: layout.implicitHeight
                ColumnLayout {
                    id: layout
                    width: parent.width
                    spacing: 0
                    ListView {
                        id: upperSection
                        visible: count && !contentView.hiddenTypes.includes(scrollView.upperType)
                        interactive: false
                        Layout.fillWidth: true
                        implicitHeight: contentHeight
                        model: scrollView.upperModel
                        delegate: scrollView.upperDelegate
                    }
                    PlasmaCore.SvgItem {
                        elementId: "horizontal-line"
                        Layout.fillWidth: true
                        Layout.leftMargin: PlasmaCore.Units.smallSpacing * 2
                        Layout.rightMargin: Layout.leftMargin
                        Layout.topMargin: PlasmaCore.Units.smallSpacing
                        svg: lineSvg
                        visible: upperSection.visible && lowerSection.visible
                    }
                    ListView {
                        id: lowerSection
                        visible: count && !contentView.hiddenTypes.includes(scrollView.lowerType)
                        interactive: false
                        Layout.fillWidth: true
                        implicitHeight: contentHeight
                        model: scrollView.lowerModel
                        delegate: scrollView.lowerDelegate
                    }
                }
            }
        }

        footer: PlasmaExtras.PlasmoidHeading {
            height: parent.header.height
            PC3.CheckBox {
                id: raiseMaximumVolumeCheckbox
                anchors.left: parent.left
                anchors.leftMargin: PlasmaCore.Units.smallSpacing
                anchors.verticalCenter: parent.verticalCenter

                checked: plasmoid.configuration.raiseMaximumVolume
                onToggled: {
                    plasmoid.configuration.raiseMaximumVolume = checked
                    if (!checked) {
                        for (var i = 0; i < paSinkModel.rowCount(); i++) {
                            if (paSinkModel.data(paSinkModel.index(i, 0), paSinkModel.role("Volume")) > PulseAudio.NormalVolume) {
                                paSinkModel.setData(paSinkModel.index(i, 0), PulseAudio.NormalVolume, paSinkModel.role("Volume"));
                            }
                        }
                        for (var i = 0; i < paSourceModel.rowCount(); i++) {
                            if (paSourceModel.data(paSourceModel.index(i, 0), paSourceModel.role("Volume")) > PulseAudio.NormalVolume) {
                                paSourceModel.setData(paSourceModel.index(i, 0), PulseAudio.NormalVolume, paSourceModel.role("Volume"));
                            }
                        }
                    }
                }
                text: i18n("Raise maximum volume")
            }
        }
    }

    function action_forceMute() {
        if (!globalMute) {
            enableGlobalMute();
        } else {
            disableGlobalMute();
        }
    }

    function action_openKcm() {
        KQCAddons.KCMShell.openSystemSettings("kcm_pulseaudio");
    }

    Component.onCompleted: {
        MicrophoneIndicator.init();

        plasmoid.setAction("forceMute", i18n("Force mute all playback devices"), "audio-volume-muted");
        plasmoid.action("forceMute").checkable = true;
        plasmoid.action("forceMute").checked = Qt.binding(() => globalMute);

        // FIXME only while Multi-page KCMs are broken when embedded in plasmoid config
        plasmoid.setAction("openKcm", i18n("&Configure Audio Devices…"), "audio-volume-high");
        plasmoid.action("openKcm").visible = (KQCAddons.KCMShell.authorize("kcm_pulseaudio.desktop").length > 0);
    }
}
