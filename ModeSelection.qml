// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura

Rectangle
{
    property var model
    property var currentIndex:
    {
        var index = Math.round(UM.Preferences.getValue("cura/active_mode"));
        if(index != null && !isNaN(index))
        {
            return index;
        }
        return 0;
    }

    color: UM.Theme.getColor("sidebar_header_bar")

    ComboBox
    {
        id: viewModeButton

        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: UM.Theme.getSize("default_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("sidebar_margin").width
        }

        style: UM.Theme.styles.combobox

        model: parent.model
        currentIndex: parent.currentIndex
        onCurrentIndexChanged:
        {
            parent.currentIndex = currentIndex;
        }
    }
}