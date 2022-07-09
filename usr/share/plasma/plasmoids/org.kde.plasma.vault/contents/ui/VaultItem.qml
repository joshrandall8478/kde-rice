/*
 *   SPDX-FileCopyrightText: 2017, 2018, 2019 Ivan Cukic <ivan.cukic (at) kde.org>
 *   SPDX-FileCopyrightText: 2020 Nate Graham <nate@kde.org>
 *
 *   SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.1
import QtQuick.Controls 2.12

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.extras 2.0 as PlasmaExtras

PlasmaExtras.ExpandableListItem {
    id: expandableListItem
    property var vaultsModelActions: Plasmoid.nativeInterface.vaultsModel.actionsModel()

    icon: model.icon
    iconEmblem: model.message.length !== 0 ? "emblem-error" :
                            model.isOpened ? "emblem-mounted" :
                        model.isOfflineOnly ? "network-disconnect" :
                                                ""
    title: model.name
    subtitle: model.message
    subtitleCanWrap: true
    defaultActionButtonAction: Action {
        icon.name: model.isOpened ? "lock" : "unlock"
        text: model.isOpened ? i18nd("plasmavault-kde", "Lock Vault") : i18nd("plasmavault-kde", "Unlock and Open")
        onTriggered: {
            if (model.isOpened) {
                vaultsModelActions.toggle(model.device);
            } else {
                vaultsModelActions.openInFileManager(model.device);
            }
        }
    }
    isBusy: Plasmoid.busy
    enabled: model.isEnabled
    contextualActionsModel: [
        Action {
            enabled: model.isOpened
            icon.name: "document-open-folder"
            text: i18nd("plasmavault-kde", "Show in File Manager")
            onTriggered: {
                vaultsModelActions.openInFileManager(model.device);
            }
        },
        Action {
            icon.name: model.isOpened ? "window-close" : "unlock"
            text: model.isOpened ? i18nd("plasmavault-kde", "Forcefully Lock Vault") : i18nd("plasmavault-kde", "Unlock Vault")
            onTriggered: {
                if (model.isOpened) {
                    vaultsModelActions.forceClose(model.device);
                } else {
                    vaultsModelActions.toggle(model.device);
                }
            }
        },
        Action {
            icon.name: "configure"
            text: i18nd("plasmavault-kde", "Configure Vault…")
            onTriggered: vaultsModelActions.configure(model.device);
        }
    ]
}
