/*
    SPDX-FileCopyrightText: 2020 Niccolò Venerandi <niccolo@venerandi.com>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick 2.4
import QtQuick.Layouts 1.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras

Rectangle {
    id: root
    readonly property bool editMode : Plasmoid.nativeInterface.containment.editMode

    color: editMode ? PlasmaCore.Theme.buttonFocusColor : "transparent" // So that user can identify the Plasmoid in edit mode
    Layout.minimumWidth:   editMode ? units.largeSpacing : 1 // We don't have zeroSpacing and assigning 0 does not work as well
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumWidth:   Layout.minimumWidth

    Layout.minimumHeight: Layout.minimumWidth
    Layout.preferredHeight: Layout.minimumHeight
    Layout.maximumHeight: Layout.minimumHeight

    Plasmoid.constraintHints: PlasmaCore.Types.MarginAreasSeparator
    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
}
