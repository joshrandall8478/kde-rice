/*
    SPDX-FileCopyrightText: 2013-2017 Jan Grulich <jgrulich@redhat.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick 2.2
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3

MouseArea {
    id: panelIconWidget

    anchors.fill: parent
    hoverEnabled: true

    onClicked: plasmoid.expanded = !plasmoid.expanded

    PlasmaCore.IconItem {
        id: connectionIcon

        anchors.fill: parent
        source: connectionIconProvider.connectionIcon
        colorGroup: PlasmaCore.ColorScope.colorGroup
        active: parent.containsMouse

        PlasmaComponents3.BusyIndicator {
            id: connectingIndicator

            anchors.centerIn: parent
            height: Math.min (parent.width, parent.height)
            width: height
            running: connectionIconProvider.connecting
            visible: running
        }
    }
}
