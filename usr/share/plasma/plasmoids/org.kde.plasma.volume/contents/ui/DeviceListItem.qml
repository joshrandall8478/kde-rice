/*
    SPDX-FileCopyrightText: 2014-2015 Harald Sitter <sitter@kde.org>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick 2.0

import org.kde.plasma.private.volume 0.1

import "../code/icon.js" as Icon

ListItemBase {
    readonly property var currentPort: model.Ports[model.ActivePortIndex]
    readonly property bool muted: model.Muted
    readonly property int activePortIndex: model.ActivePortIndex

    fullNameToShowOnHover: ListView.view.count === 1 ? model.Description : ""

    draggable: false
    label: {
        if (currentPort && currentPort.description) {
            if (ListView.view.count === 1 || !model.Description) {
                return currentPort.description;
            } else {
                return i18nc("label of device items", "%1 (%2)", currentPort.description, model.Description);
            }
        }
        if (model.Description) {
            return model.Description;
        }
        if (model.Name) {
            return model.Name;
        }
        return i18n("Device name not found");
    }

    onActivePortIndexChanged: {
        if (type === "sink" && globalMute && !model.Muted) {
            model.Muted = true;
        }
    }

    onMutedChanged: {
        if (type === "sink" && globalMute && !model.Muted) {
            plasmoid.configuration.globalMuteDevices = [];
            plasmoid.configuration.globalMute = false;
            globalMute = false;
        }
    }
}
