/*
    SPDX-FileCopyrightText: 2013-2017 Jan Grulich <jgrulich@redhat.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick 2.2
import QtQuick.Layouts 1.2
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.networkmanagement 0.2 as PlasmaNM

PlasmaExtras.Representation {
    id: full
    collapseMarginsHint: true
    property alias toolbarValues: toolbar

    PlasmaNM.AvailableDevices {
        id: availableDevices
    }

    Component {
        id: networkModelComponent
        PlasmaNM.NetworkModel {}
    }

    property PlasmaNM.NetworkModel connectionModel: null

    PlasmaNM.AppletProxyModel {
        id: appletProxyModel

        sourceModel: full.connectionModel
    }

    header: PlasmaExtras.PlasmoidHeading {
        focus: true
        Toolbar {
            id: toolbar
            width: parent.width
        }
    }

    Keys.onPressed: {
        function goToCurrent() {
            connectionView.positionViewAtIndex(connectionView.currentIndex, ListView.Contain);
            if (connectionView.currentIndex != -1) {
                connectionView.currentItem.forceActiveFocus();
            }
        }
        if (event.modifiers & Qt.ControlModifier && event.key == Qt.Key_F) {
            toolbar.searchTextField.forceActiveFocus();
            toolbar.searchTextField.selectAll();
            event.accepted = true;
        } else if (event.key == Qt.Key_Down) {
            connectionView.incrementCurrentIndex();
            goToCurrent()
            event.accepted = true;
        } else if (event.key == Qt.Key_Up) {
            if (connectionView.currentIndex == 0) {
                connectionView.currentIndex = -1;
                toolbar.searchTextField.forceActiveFocus();
                toolbar.searchTextField.selectAll();
            } else {
                connectionView.decrementCurrentIndex();
                goToCurrent();
            }
            event.accepted = true;
        }
    }

    PlasmaComponents3.ScrollView {
        id: scrollView
        anchors.fill: parent

        // HACK: workaround for https://bugreports.qt.io/browse/QTBUG-83890
        PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff

        contentWidth: availableWidth - contentItem.leftMargin - contentItem.rightMargin

        contentItem: ListView {
            id: connectionView

            property int currentVisibleButtonIndex: -1
            property bool showSeparator: false

            Loader {
                anchors.centerIn: parent
                width: parent.width - (PlasmaCore.Units.largeSpacing * 4)
                active: connectionView.count === 0
                asynchronous: true
                visible: status == Loader.Ready
                sourceComponent: PlasmaExtras.PlaceholderMessage {
                    iconName: {
                        if (toolbarValues.displayplaneModeMessage) {
                            return "network-flightmode-on"
                        }
                        if (toolbarValues.displayWifiMessage) {
                            return "network-wireless-off"
                        }
                        if (toolbarValues.displayWwanMessage) {
                            return "network-mobile-off"
                        }
                        return "edit-none"
                    }
                    text: {
                        if (toolbarValues.displayplaneModeMessage) {
                            return i18n("Airplane mode is enabled")
                        }
                        if (toolbarValues.displayWifiMessage) {
                            if (toolbarValues.displayWwanMessage) {
                                return i18n("Wireless and mobile networks are deactivated")
                            }
                            return i18n("Wireless is deactivated")
                        }
                        if (toolbarValues.displayWwanMessage) {
                            return i18n("Mobile network is deactivated")
                        }
                        if (toolbar.searchTextField.text.length > 0) {
                            return i18n("No matches")
                        }
                        return i18n("No available connections")
                    }
                }
            }

            topMargin: PlasmaCore.Units.smallSpacing * 2
            bottomMargin: PlasmaCore.Units.smallSpacing * 2
            leftMargin: PlasmaCore.Units.smallSpacing * 2
            rightMargin: PlasmaCore.Units.smallSpacing * 2
            spacing: PlasmaCore.Units.smallSpacing
            model: appletProxyModel
            currentIndex: -1
            boundsBehavior: Flickable.StopAtBounds
            section.property: showSeparator ? "Section" : ""
            section.delegate: ListItem {
                separator: true
            }
            highlight: PlasmaExtras.Highlight { }
            highlightMoveDuration: 0
            highlightResizeDuration: 0
            delegate: ConnectionItem {
                width: connectionView.width - PlasmaCore.Units.smallSpacing * 4
            }
        }
    }

    Connections {
        target: plasmoid
        function onExpandedChanged(expanded) {
            connectionView.currentVisibleButtonIndex = -1;

            if (expanded) {
                handler.requestScan();
                full.connectionModel = networkModelComponent.createObject(full)
            } else {
                full.connectionModel.destroy()
            }
        }
    }
}
