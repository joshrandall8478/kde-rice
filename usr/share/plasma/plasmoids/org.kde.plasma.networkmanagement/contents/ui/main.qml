/*
    SPDX-FileCopyrightText: 2013-2017 Jan Grulich <jgrulich@redhat.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick 2.2
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.networkmanagement 0.2 as PlasmaNM
import org.kde.kquickcontrolsaddons 2.0
import QtQuick.Layouts 1.1

Item {
    id: mainWindow

    readonly property string kcm: "kcm_networkmanagement"
    readonly property bool kcmAuthorized: KCMShell.authorize("kcm_networkmanagement.desktop").length == 1

    Plasmoid.toolTipMainText: i18n("Networks")
    Plasmoid.toolTipSubText: networkStatus.activeConnections
    Plasmoid.icon: connectionIconProvider.connectionTooltipIcon
    Plasmoid.switchWidth: PlasmaCore.Units.gridUnit * 10
    Plasmoid.switchHeight: PlasmaCore.Units.gridUnit * 10
    Plasmoid.compactRepresentation: CompactRepresentation { }
    Plasmoid.fullRepresentation: PopupDialog {
        id: dialogItem
        Layout.minimumWidth: PlasmaCore.Units.iconSizes.medium * 10
        Layout.minimumHeight: PlasmaCore.Units.gridUnit * 20
        anchors.fill: parent
        focus: true
    }

    function action_openKCM() {
        KCMShell.openSystemSettings(kcm)
    }

    function action_showPortal() {
        Qt.openUrlExternally("http://networkcheck.kde.org")
    }

    Component.onCompleted: {
        if (kcmAuthorized) {
            plasmoid.setAction("openKCM", i18n("&Configure Network Connections…"), "configure");
        }
        plasmoid.removeAction("configure");
        plasmoid.setAction("showPortal", i18n("Open Network Login Page…"), "internet-services");

        const action = plasmoid.action("showPortal");
        action.visible = Qt.binding(function() { return connectionIconProvider.needsPortal; })
    }

    PlasmaNM.NetworkStatus {
        id: networkStatus
    }

    PlasmaNM.ConnectionIcon {
        id: connectionIconProvider
    }

    PlasmaNM.Handler {
        id: handler
    }

    Timer {
        id: scanTimer
        interval: 10200
        repeat: true
        running: plasmoid.expanded && !connectionIconProvider.airplaneMode

        onTriggered: handler.requestScan()
    }
}
