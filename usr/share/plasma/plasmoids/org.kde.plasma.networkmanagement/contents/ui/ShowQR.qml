/*
    SPDX-FileCopyrightText: 2019 Aleix Pol Gonzalez <aleixpol@kde.org>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

import org.kde.kirigami 2.3 as Kirigami
import org.kde.prison 1.0 as Prison

Window {
    id: window
    color: Qt.rgba(0, 0, 0, 0.3)
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    property alias content: dataInput.content

    function destroyWindow() {
        window.close();
        window.destroy();
    }

    Shortcut {
        sequences: [StandardKey.Back, StandardKey.Cancel, StandardKey.Close, StandardKey.Delete, StandardKey.Quit]
        onActivated: window.destroyWindow()
    }

    MouseArea {
        anchors.fill: parent

        onClicked: window.destroyWindow()

        Prison.Barcode {
            id: dataInput

            anchors {
                fill: parent
                margins: Kirigami.Units.largeSpacing * 4
            }

            barcodeType: "QRCode"
        }
    }
}
