/*
    SPDX-FileCopyrightText: 2014-2015 Harald Sitter <sitter@kde.org>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick 2.0

import org.kde.plasma.private.volume 0.1

ListItemBase {
    id: item

    property QtObject devicesModel

    draggable: devicesModel && devicesModel.count > 1
    label: {
        if (model.Client && model.Client.name && model.Client.name != "pipewire-media-session") {
            return model.Client.name;
        }
        if (model.Name) {
            return model.Name;
        }
        return i18n("Stream name not found");
    }
    fullNameToShowOnHover: {
        if (devicesModel.count > 1) {
            const indexRole = devicesModel.role("Index");
            const descriptionRole = devicesModel.role("Description");

            for (let i = 0; i < devicesModel.count; ++i) {
                const idx = devicesModel.index(i, 0);
                const deviceIndex = devicesModel.data(idx, indexRole);

                if (deviceIndex !== model.DeviceIndex) {
                    continue;
                }

                return devicesModel.data(idx, descriptionRole);
            }
        }

        return "";
    }

    iconSource: {
        if (model.IconName.length !== 0) {
            return model.IconName
        }

        if (item.type === "source-output") {
            return "audio-input-microphone"
        }

        return "audio-volume-high"
    }
    iconUsesPlasmaTheme: false
}
