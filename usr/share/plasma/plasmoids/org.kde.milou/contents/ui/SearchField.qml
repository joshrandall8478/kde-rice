/*
 * This file is part of the KDE Milou Project
 * SPDX-FileCopyrightText: 2013-2014 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 *
 */

import QtQuick 2.1

import org.kde.plasma.components 3.0 as PlasmaComponents3
import "globals.js" as Globals

/*
 * The SearchField is a simple text field widget. The only complex part
 * is the internal timer to reduce the number of textChanged signals
 * using searchTextChanged.
 */
Item {
    signal searchTextChanged()
    signal close()
    property alias text: textField.text

    height: childrenRect.height
    width: Globals.PlasmoidWidth

    PlasmaComponents3.TextField {
        id: textField
        clearButtonShown: true
        placeholderText: i18n("Search...")
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        focus: true
        Keys.forwardTo: listView

        // We do not want to send the text instantly as that would result
        // in too many queries. Therefore we add a small 200msec delay
        Timer {
            id: timer
            interval: 200
            onTriggered: searchTextChanged()
        }

        onTextChanged: timer.restart()
    }

    function selectAll() {
        textField.selectAll()
    }

    function setFocus() {
        textField.focus = true
    }

    Keys.onEscapePressed: {
        if (textField.text) {
            textField.text = ""
        } else {
            close()
        }
    }
}
