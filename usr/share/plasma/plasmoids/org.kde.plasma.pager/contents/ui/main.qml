/*
    SPDX-FileCopyrightText: 2012 Luís Gabriel Lima <lampih@gmail.com>
    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2016 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddonsComponents
import org.kde.draganddrop 2.0
import org.kde.plasma.private.pager 2.0
import org.kde.plasma.activityswitcher 1.0 as ActivitySwitcher

MouseArea {
    id: root

    property bool isActivityPager: (plasmoid.pluginName === "org.kde.plasma.activitypager")
    property bool vertical: (plasmoid.formFactor === PlasmaCore.Types.Vertical)

    readonly property real aspectRatio: (((pagerModel.pagerItemSize.width * pagerItemGrid.effectiveColumns)
        + ((pagerItemGrid.effectiveColumns * pagerItemGrid.spacing) - pagerItemGrid.spacing))
        / ((pagerModel.pagerItemSize.height * pagerItemGrid.effectiveRows)
        + ((pagerItemGrid.effectiveRows * pagerItemGrid.spacing) - pagerItemGrid.spacing)))

    Layout.minimumWidth: !root.vertical ? Math.floor(height * aspectRatio) : 1
    Layout.minimumHeight: root.vertical ? Math.floor(width / aspectRatio) : 1

    Layout.maximumWidth: !root.vertical ? Math.floor(height * aspectRatio) : Infinity
    Layout.maximumHeight: root.vertical ? Math.floor(width / aspectRatio) : Infinity

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
    Plasmoid.status: pagerModel.shouldShowPager ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus

    Layout.fillWidth: root.vertical
    Layout.fillHeight: !root.vertical

    property bool dragging: false
    property string dragId

    property int dragSwitchDesktopIndex: -1

    property int wheelDelta: 0

    anchors.fill: parent
    acceptedButtons: Qt.NoButton

    hoverEnabled: true

    function colorWithAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    readonly property color windowActiveOnActiveDesktopColor: colorWithAlpha(PlasmaCore.Theme.textColor, 0.6)
    readonly property color windowInactiveOnActiveDesktopColor: colorWithAlpha(PlasmaCore.Theme.textColor, 0.35)
    readonly property color windowActiveColor: colorWithAlpha(theme.textColor, 0.5)
    readonly property color windowActiveBorderColor: PlasmaCore.Theme.textColor
    readonly property color windowInactiveColor: colorWithAlpha(PlasmaCore.Theme.textColor, 0.17)
    readonly property color windowInactiveBorderColor: colorWithAlpha(PlasmaCore.Theme.textColor, 0.5)

    function action_addDesktop() {
        pagerModel.addDesktop();
    }

    function action_removeDesktop() {
        pagerModel.removeDesktop();
    }

    function action_openKCM() {
        KQuickControlsAddonsComponents.KCMShell.openSystemSettings("kcm_kwin_virtualdesktops");
    }

    function action_showActivityManager() {
        ActivitySwitcher.Backend.toggleActivityManager()
    }

    function generateWindowList(windows) {
        // if we have 5 windows, we would show "4 and another one" with the
        // hint that there's 1 more taking the same amount of space than just showing it
        const maximum = windows.length === 5 ? 5 : 4

        let text = "<ul><li>"
        + windows.slice(0, maximum).map(title => title.replace(/[^0-9A-Za-z ]/g,
            c => "&#" + c.charCodeAt(0) + ";")).join("</li><li>")
                + "</li></ul>";

        if (windows.length > maximum) {
            text += i18np("…and %1 other window", "…and %1 other windows", windows.length - maximum)
        }

        return text
    }

    onContainsMouseChanged: {
        if (!containsMouse && dragging) {
            // Somewhat heavy-handed way to clean up after a window delegate drag
            // exits the window.
            pagerModel.refresh();
            dragging = false;
        }
    }

    onWheel: {
        // Magic number 120 for common "one click, see:
        // https://doc.qt.io/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
        wheelDelta += wheel.angleDelta.y || wheel.angleDelta.x;

        let increment = 0;

        while (wheelDelta >= 120) {
            wheelDelta -= 120;
            increment++;
        }

        while (wheelDelta <= -120) {
            wheelDelta += 120;
            increment--;
        }

        while (increment !== 0) {
            if (increment < 0) {
                const nextPage = plasmoid.configuration.wrapPage?
                    (pagerModel.currentPage + 1) % repeater.count :
                    Math.min(pagerModel.currentPage + 1, repeater.count - 1);
                pagerModel.changePage(nextPage);
            } else {
                const previousPage = plasmoid.configuration.wrapPage ?
                    (repeater.count + pagerModel.currentPage - 1) % repeater.count :
                    Math.max(pagerModel.currentPage - 1, 0);
                pagerModel.changePage(previousPage);
            }

            increment += (increment < 0) ? 1 : -1;
        }
    }

    PagerModel {
        id: pagerModel

        enabled: root.visible

        showDesktop: (plasmoid.configuration.currentDesktopSelected === 1)

        showOnlyCurrentScreen: plasmoid.configuration.showOnlyCurrentScreen
        screenGeometry: plasmoid.screenGeometry

        pagerType: isActivityPager ? PagerModel.Activities : PagerModel.VirtualDesktops
    }

    Connections {
        target: plasmoid.configuration

        function onShowWindowIconsChanged() {
            // Causes the model to reset; Component.onCompleted in the
            // window delegate now gets a chance to create the icon item,
            // which it otherwise will not do.
            pagerModel.refresh();
        }

        function onDisplayedTextChanged() {
            // Causes the model to reset; Component.onCompleted in the
            // desktop delegate now gets a chance to create the label item,
            // which it otherwise will not do.
            pagerModel.refresh();
        }
    }

    Component {
        id: desktopLabelComponent

        PlasmaComponents3.Label {
            anchors {
                fill: parent
                topMargin: desktopFrame.margins.top
                bottomMargin: desktopFrame.margins.bottom
                leftMargin: desktopFrame.margins.left
                rightMargin: desktopFrame.margins.right
            }

            property int index: 0
            property var model: null
            property Item desktopFrame: null

            text: plasmoid.configuration.displayedText ? model.display : index + 1

            wrapMode: Text.NoWrap
            elide: Text.ElideRight

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            font.pixelSize: Math.min(height, PlasmaCore.Theme.defaultFont.pixelSize)

            z: 9999 // The label goes above everything
        }
    }

    Component {
        id: windowIconComponent

        PlasmaCore.IconItem {
            anchors.centerIn: parent

            height: Math.min(PlasmaCore.Units.iconSizes.small,
                             parent.height,
                             Math.max(parent.height - (PlasmaCore.Units.smallSpacing * 2),
                                      PlasmaCore.Units.smallSpacing * 2))
            width: Math.min(PlasmaCore.Units.iconSizes.small,
                            parent.width,
                            Math.max(parent.width - (PlasmaCore.Units.smallSpacing * 2),
                                     PlasmaCore.Units.smallSpacing * 2))

            property var model: null

            source: model ? model.decoration : undefined
            usesPlasmaTheme: false
            roundToIconSize: false
            animated: false
        }
    }

    Timer {
        id: dragTimer
        interval: 1000
        onTriggered: {
            if (dragSwitchDesktopIndex !== -1 && dragSwitchDesktopIndex !== pagerModel.currentPage) {
                pagerModel.changePage(dragSwitchDesktopIndex);
            }
        }
    }

    Grid {
        id: pagerItemGrid

        spacing: PlasmaCore.Units.devicePixelRatio
        rows: effectiveRows
        columns: effectiveColumns

        z: 1

        readonly property int effectiveRows: {
            if (!pagerModel.count) {
                return 1;
            }

            let rows = 1;

            if (isActivityPager && plasmoid.configuration.pagerLayout !== 0 /*No Default*/) {
                if (plasmoid.configuration.pagerLayout === 1 /*Horizontal*/) {
                    rows = 1;
                } else if (plasmoid.configuration.pagerLayout === 2 /*Vertical*/) {
                    rows = pagerModel.count;
                }
            } else {
                let columns = Math.floor(pagerModel.count / pagerModel.layoutRows);

                if (pagerModel.count % pagerModel.layoutRows > 0) {
                    columns += 1;
                }

                rows = Math.floor(pagerModel.count / columns);

                if (pagerModel.count % columns > 0) {
                    rows += 1;
                }
            }

            return rows;
        }

        readonly property int effectiveColumns: {
            if (!pagerModel.count) {
                return 1;
            }

            return Math.ceil(pagerModel.count / effectiveRows);
        }

        readonly property real pagerItemSizeRatio: pagerModel.pagerItemSize.width / pagerModel.pagerItemSize.height
        readonly property real widthScaleFactor: columnWidth / pagerModel.pagerItemSize.width
        readonly property real heightScaleFactor: rowHeight / pagerModel.pagerItemSize.height


        states: [
            State {
                name: "vertical"
                when: vertical
                PropertyChanges {
                    target: pagerItemGrid
                    innerSpacing: effectiveColumns
                    rowHeight: Math.floor(columnWidth / pagerItemSizeRatio)
                    columnWidth: Math.floor((root.width - innerSpacing) / effectiveColumns)
                }
            }
        ]

        property int innerSpacing: (effectiveRows - 1) * spacing
        property int rowHeight: Math.floor((root.height - innerSpacing) / effectiveRows)
        property int columnWidth: Math.floor(rowHeight * pagerItemSizeRatio)

        Repeater {
            id: repeater
            model: pagerModel

            PlasmaCore.ToolTipArea {
                id: desktop

                property string desktopId: isActivityPager ? model.TasksModel.activity : model.TasksModel.virtualDesktop
                property bool active: (index === pagerModel.currentPage)

                mainText: model.display
                // our ToolTip has maximumLineCount of 8 which doesn't fit but QML doesn't
                // respect that in RichText so we effectively can put in as much as we like :)
                // it also gives us more flexibility when it comes to styling the <li>
                textFormat: Text.RichText

                function updateSubTextIfNeeded() {
                    if (!containsMouse) {
                        return;
                    }

                    let text = ""
                    let visibleWindows = []
                    let minimizedWindows = []

                    for (let i = 0, length = windowRectRepeater.count; i < length; ++i) {
                        const window = windowRectRepeater.itemAt(i)
                        if (window) {
                            if (window.minimized) {
                                minimizedWindows.push(window.visibleName)
                            } else {
                                visibleWindows.push(window.visibleName)
                            }
                        }
                    }

                    if (visibleWindows.length === 1) {
                        text += visibleWindows[0]
                    } else if (visibleWindows.length > 1) {
                        text += i18np("%1 Window:", "%1 Windows:", visibleWindows.length)
                            + generateWindowList(visibleWindows)
                    }

                    if (visibleWindows.length && minimizedWindows.length) {
                        if (visibleWindows.length === 1) {
                            text += "<br>"
                        }
                        text += "<br>"
                    }

                    if (minimizedWindows.length > 0) {
                        text += i18np("%1 Minimized Window:", "%1 Minimized Windows:", minimizedWindows.length)
                            + generateWindowList(minimizedWindows)
                    }

                    if (text.length) {
                        // Get rid of the spacing <ul> would cause
                        text = "<style>ul { margin: 0; }</style>" + text
                    }

                    subText = text
                }

                width: pagerItemGrid.columnWidth
                height: pagerItemGrid.rowHeight

                PlasmaCore.FrameSvgItem {
                    id: desktopFrame

                    anchors.fill: parent
                    z: 2 // Above window outlines, but below label
                    imagePath: "widgets/pager"
                    prefix: (desktopMouseArea.enabled && desktopMouseArea.containsMouse) || (root.dragging && root.dragId == desktopId) ?
                                "hover" : (desktop.active ? "active" : "normal")
                }

                DropArea {
                    id: droparea
                    anchors.fill: parent
                    preventStealing: true

                    onDragEnter: {
                        root.dragSwitchDesktopIndex = index;
                        dragTimer.start();
                    }
                    onDragLeave: {
                        root.dragSwitchDesktopIndex = -1;
                        dragTimer.stop();
                    }
                    onDrop: {
                        pagerModel.drop(event.mimeData, event.modifiers, desktop.desktopId);
                        root.dragSwitchDesktopIndex = -1;
                        dragTimer.stop();
                    }
                }

                MouseArea {
                    id: desktopMouseArea
                    anchors.fill: parent
                    hoverEnabled : true
                    activeFocusOnTab: true
                    onClicked: pagerModel.changePage(index);
                    Accessible.name: plasmoid.configuration.displayedText ? model.display : i18n("Desktop %1", (index + 1))
                    Accessible.description: plasmoid.configuration.displayedText ? i18n("Activate %1", model.display) : i18n("Activate %1", (index + 1))
                    Accessible.role: Accessible.Button
                    Keys.onPressed: {
                        switch (event.key) {
                        case Qt.Key_Space:
                        case Qt.Key_Enter:
                        case Qt.Key_Return:
                        case Qt.Key_Select:
                            pagerModel.changePage(index);
                            break;
                        }
                    }
                }

                Item {
                    id: clipRect
                    x: Math.round(PlasmaCore.Units.devicePixelRatio)
                    y: Math.round(PlasmaCore.Units.devicePixelRatio)
                    width: desktop.width - 2 * x
                    height: desktop.height - 2 * y

                    z: 1 // Below FrameSvg

                    Repeater {
                        id: windowRectRepeater

                        model: TasksModel

                        onCountChanged: desktop.updateSubTextIfNeeded()

                        Rectangle {
                            id: windowRect

                            z: 1 + model.StackingOrder

                            property rect geometry: model.Geometry
                            property string visibleName: model.display
                            property bool minimized: (model.IsMinimized === true)
                            onMinimizedChanged: desktop.updateSubTextIfNeeded()
                            onVisibleNameChanged: desktop.updateSubTextIfNeeded()

                            /* since we move clipRect with 1, move it back */
                            x: (geometry.x * pagerItemGrid.widthScaleFactor) - Math.round(PlasmaCore.Units.devicePixelRatio)
                            y: (geometry.y * pagerItemGrid.heightScaleFactor) - Math.round(PlasmaCore.Units.devicePixelRatio)
                            width: geometry.width * pagerItemGrid.widthScaleFactor
                            height: geometry.height * pagerItemGrid.heightScaleFactor
                            visible: model.IsMinimized !== true
                            color: {
                                if (desktop.active) {
                                    if (model.IsActive === true)
                                        return windowActiveOnActiveDesktopColor;
                                    else
                                        return windowInactiveOnActiveDesktopColor;
                                } else {
                                    if (model.IsActive === true)
                                        return windowActiveColor;
                                    else
                                        return windowInactiveColor;
                                }
                            }

                            border.width: Math.round(PlasmaCore.Units.devicePixelRatio)
                            border.color: (model.IsActive === true) ? windowActiveBorderColor
                                                    : windowInactiveBorderColor

                            MouseArea {
                                id: windowMouseArea
                                anchors.fill: parent

                                drag.target: windowRect
                                drag.axis: Drag.XandYAxis
                                drag.minimumX: -windowRect.width/2
                                drag.maximumX: root.width - windowRect.width/2
                                drag.minimumY: -windowRect.height/2
                                drag.maximumY: root.height - windowRect.height/2

                                drag.onActiveChanged: {
                                    root.dragging = drag.active;
                                    root.dragId = desktop.desktopId;
                                    desktopMouseArea.enabled = !drag.active;

                                    if (drag.active) {
                                        // Reparent to allow drags outside of this desktop.
                                        const value = root.mapFromItem(clipRect, windowRect.x, windowRect.y);
                                        windowRect.parent = root;
                                        windowRect.x = value.x;
                                        windowRect.y = value.y
                                    }
                                }

                                onReleased: {
                                    if (root.dragging) {
                                        windowRect.visible = false;
                                        const windowCenter = Qt.point(windowRect.x + windowRect.width / 2, windowRect.y + windowRect.height / 2);
                                        const pagerItem = pagerItemGrid.childAt(windowCenter.x, windowCenter.y);

                                        if (pagerItem) {
                                            const relativeTopLeft = root.mapToItem(pagerItem, windowRect.x, windowRect.y);

                                            const modelIndex = windowRectRepeater.model.index(index, 0)
                                            pagerModel.moveWindow(modelIndex, relativeTopLeft.x, relativeTopLeft.y,
                                                pagerItem.desktopId, root.dragId,
                                                pagerItemGrid.widthScaleFactor, pagerItemGrid.heightScaleFactor);
                                        }

                                        // Will reset the model, destroying the reparented drag delegate that
                                        // is no longer bound to model.Geometry.
                                        root.dragging = false;
                                        pagerModel.refresh();
                                    } else {
                                        // When there is no dragging (just a click), the event is passed
                                        // to the desktop MouseArea.
                                        desktopMouseArea.clicked(mouse);
                                    }
                                }
                            }

                            Component.onCompleted: {
                                if (plasmoid.configuration.showWindowIcons) {
                                    windowIconComponent.createObject(windowRect, {"model": model});
                                }
                            }
                        }
                    }
                }

                Component.onCompleted: {
                    if (plasmoid.configuration.displayedText < 2) {
                        desktopLabelComponent.createObject(desktop, {"index": index, "model": model, "desktopFrame": desktopFrame});
                    }
                }

                onContainsMouseChanged: updateSubTextIfNeeded()
            }
        }
    }

    Component.onCompleted: {
        if (isActivityPager) {
            plasmoid.setAction("showActivityManager", i18n("Show Activity Manager…"), "activities");
        } else {
            if (KQuickControlsAddonsComponents.KCMShell.authorize("kcm_kwin_virtualdesktops.desktop").length > 0) {
                plasmoid.setAction("addDesktop", i18n("Add Virtual Desktop"), "list-add");
                plasmoid.setAction("removeDesktop", i18n("Remove Virtual Desktop"), "list-remove");
                plasmoid.action("removeDesktop").enabled = Qt.binding(function() {
                    return repeater.count > 1;
                });

                plasmoid.setAction("openKCM", i18n("Configure Virtual Desktops…"), "configure");
            }
        }
    }
}
