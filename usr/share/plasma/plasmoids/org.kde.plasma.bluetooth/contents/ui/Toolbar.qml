/*
    SPDX-FileCopyrightText: 2013-2014 Jan Grulich <jgrulich@redhat.com>
    SPDX-FileCopyrightText: 2014-2015 David Rosca <nowrep@gmail.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick 2.2
import QtQuick.Layouts 1.2
import org.kde.kquickcontrolsaddons 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.private.bluetooth 1.0 as PlasmaBt

PlasmaExtras.PlasmoidHeading {
    id: toolbar

    leftPadding: PlasmaCore.Units.smallSpacing
    contentItem: RowLayout {
        spacing: PlasmaCore.Units.smallSpacing

        PlasmaComponents3.CheckBox {
            text: i18n("Enable Bluetooth")
            icon.name: "preferences-system-bluetooth"
            checked: btManager.bluetoothOperational
            enabled: btManager.bluetoothBlocked || btManager.adapters.length
            onToggled: toggleBluetooth()
        }

        Item {
            Layout.fillWidth: true
        }

        PlasmaComponents3.ToolButton {
            id: addDeviceButton

            visible: !(plasmoid.containmentDisplayHints & PlasmaCore.Types.ContainmentDrawsPlasmoidHeading)
            enabled: !btManager.bluetoothBlocked

            icon.name: "list-add"

            onClicked: plasmoid.action("addNewDevice").trigger()

            PlasmaComponents3.ToolTip {
                text: plasmoid.action("addNewDevice").text
            }
        }

        PlasmaComponents3.ToolButton {
            id: openSettingsButton

            visible: plasmoid.action("configure").enabled && !(plasmoid.containmentDisplayHints & PlasmaCore.Types.ContainmentDrawsPlasmoidHeading)
            icon.name: "configure"
            onClicked: plasmoid.action("configure").trigger()

            PlasmaComponents3.ToolTip {
                text: plasmoid.action("configure").text
            }
            Accessible.name: plasmoid.action("configure").text
        }
    }
}
