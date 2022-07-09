/*
    SPDX-FileCopyrightText: 2013-2017 Jan Grulich <jgrulich@redhat.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick 2.2
import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddons
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents // for ContextMenu+MenuItem
import org.kde.plasma.components 3.0 as PlasmaComponents3

Column {
    property var details: []

    KQuickControlsAddons.Clipboard {
        id: clipboard
    }

    PlasmaComponents.ContextMenu {
        id: contextMenu
        property string text

        function show(item, text, x, y) {
            contextMenu.text = text
            visualParent = item
            open(x, y)
        }

        PlasmaComponents.MenuItem {
            text: i18n("Copy")
            icon: "edit-copy"
            enabled: contextMenu.text !== ""
            onClicked: clipboard.content = contextMenu.text
        }
    }

    Repeater {
        id: repeater

        property int contentHeight: 0
        property int longestString: 0

        model: details.length / 2

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: Math.max(detailNameLabel.height, detailValueLabel.height)

            PlasmaComponents3.Label {
                id: detailNameLabel

                anchors {
                    left: parent.left
                    leftMargin: repeater.longestString - paintedWidth + Math.round(PlasmaCore.Units.gridUnit / 2)
                }
                font: PlasmaCore.Theme.smallestFont
                horizontalAlignment: Text.AlignRight
                text: details[index*2] + ": "
                opacity: 0.6

                Component.onCompleted: {
                    if (paintedWidth > repeater.longestString) {
                        repeater.longestString = paintedWidth
                    }
                }
            }

            PlasmaComponents3.Label {
                id: detailValueLabel

                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: repeater.longestString + Math.round(PlasmaCore.Units.gridUnit / 2)
                }
                elide: Text.ElideRight
                font: PlasmaCore.Theme.smallestFont
                text: details[(index*2)+1]
                textFormat: Text.PlainText

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onPressed: contextMenu.show(this, detailValueLabel.text, mouse.x, mouse.y)
                }
            }
        }
    }
}
