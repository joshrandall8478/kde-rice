/*
    SPDX-FileCopyrightText: 2013-2017 Jan Grulich <jgrulich@redhat.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick 2.2
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.networkmanagement 0.2 as PlasmaNM

PlasmaComponents3.TextField {
    property int/*PlasmaNM.Enums.SecurityType*/ securityType

    echoMode: TextInput.Password
    revealPasswordButtonShown: true
    placeholderText: i18n("Password…")
    validator: RegExpValidator {
        regExp: (securityType === PlasmaNM.Enums.StaticWep)
            ? /^(?:.{5}|[0-9a-fA-F]{10}|.{13}|[0-9a-fA-F]{26})$/
            : /^(?:.{8,64})$/
    }
}
