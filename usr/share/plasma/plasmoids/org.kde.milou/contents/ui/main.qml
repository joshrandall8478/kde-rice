/*
 * This file is part of the KDE Milou Project
 * SPDX-FileCopyrightText: 2013-2014 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 *
 */

import QtQuick 2.1
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.milou 0.1 as Milou

import "globals.js" as Globals

Item {
    id: mainWidget
    Plasmoid.switchWidth: Globals.SwitchWidth
    Plasmoid.switchHeight: Globals.SwitchWidth
    Layout.minimumWidth: Globals.PlasmoidWidth
    Layout.maximumWidth: Globals.PlasmoidWidth
    Layout.minimumHeight: wrapper.minimumHeight + wrapper.anchors.topMargin + wrapper.anchors.bottomMargin
    Layout.maximumHeight: Layout.minimumHeight

    function isBottomEdge() {
        return plasmoid.location == PlasmaCore.Types.BottomEdge;
    }

    Item {
        id: wrapper

        property int minimumHeight: listView.count ? listView.contentHeight + searchField.height + 5
                                                   : searchField.height
        property int maximumHeight: minimumHeight
        anchors.fill: parent


        SearchField {
            id: searchField

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.height / 2
            }
            onSearchTextChanged: {
                listView.setQueryString(text)
            }
            onClose: plasmoid.expanded = false
        }

        Milou.ResultsView {
            id: listView
            //in case is expanded
            clip: true

            anchors {
                left: parent.left
                right: parent.right
            }

            reversed: isBottomEdge()
            onActivated: {
                searchField.text = "";
                plasmoid.expanded = false;
            }
            onUpdateQueryString: function (text, cursorPosition) {
                searchField.text = text
                searchField.cursorPosition = cursorPosition
            }
        }


        Component.onCompleted: {
            //plasmoid.settingsChanged.connect(loadSettings)

            if (!isBottomEdge()) {
                // Normal view
                searchField.anchors.top = wrapper.top
                listView.anchors.top = searchField.bottom
                listView.anchors.bottom = wrapper.bottom
            }
            else {
                // When on the bottom
                listView.anchors.top = wrapper.top
                listView.anchors.bottom = searchField.top
                searchField.anchors.bottom = wrapper.bottom
            }
        }
    }

    Timer {
        id: theFocusDoesNotAlwaysWorkTimer
        interval: 100
        repeat: false

        onTriggered: {
            setTextFieldFocus(plasmoid.expanded)
        }
    }

    function setTextFieldFocus(shown) {
        searchField.setFocus();
        searchField.selectAll();
    }

    function loadSettings() {
        listView.loadSettings()
    }

    Plasmoid.onExpandedChanged: {
        setTextFieldFocus(plasmoid.expanded);
        //
        // The focus is not always set correctly. The hunch is that this
        // function is called before the popup is actually visible and
        // therfore the setFocus call does not do anything. So, we are using
        // a small timer and calling the setTextFieldFocus function again.
        //
        theFocusDoesNotAlwaysWorkTimer.start()
    }

}
