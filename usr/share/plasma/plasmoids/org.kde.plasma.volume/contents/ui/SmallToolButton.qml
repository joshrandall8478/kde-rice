/*
    SPDX-FileCopyrightText: 2017 Chris Holland <zrenfire@gmail.com>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3

PlasmaComponents3.ToolButton {
    id: smallToolButton
    readonly property int size: Math.ceil(PlasmaCore.Units.iconSizes.small + PlasmaCore.Units.smallSpacing * 2)
    implicitWidth: size
    implicitHeight: size
}
