// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.8
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura

Column
{
    id: base;

    property int currentExtruderIndex: Cura.ExtruderManager.activeExtruderIndex;
    property bool currentExtruderVisible: extrudersList.visible;

    spacing: Math.round(UM.Theme.getSize("default_margin").height)

    signal showTooltip(Item item, point location, string text)
    signal hideTooltip()

    Item
    {
        anchors
        {
            left: parent.left
            right: parent.right
        }
        visible: extruderSelectionRow.visible
        height: UM.Theme.getSize("default_lining").height
        width: height
    }

    // Extruder Row
    Item
    {
        id: extruderSelectionRow
        width: parent.width
        height: extrudersList.height
        visible: machineExtruderCount.properties.value > 1

        anchors
        {
            left: parent.left
            leftMargin: Math.round(UM.Theme.getSize("sidebar_margin").width * 0.7)
            right: parent.right
            rightMargin: Math.round(UM.Theme.getSize("sidebar_margin").width * 0.7)
            topMargin: UM.Theme.getSize("default_margin").height
        }

        ListView
        {
            id: extrudersList
            property var index: 0

            height: Math.round(UM.Theme.getSize("setting_control").height)
            width: Math.round(parent.width)
            boundsBehavior: Flickable.StopAtBounds

            anchors
            {
                left: parent.left
                leftMargin: Math.round(UM.Theme.getSize("default_margin").width / 2)
                right: parent.right
                rightMargin: Math.round(UM.Theme.getSize("default_margin").width / 2)
                verticalCenter: parent.verticalCenter
            }

            ExclusiveGroup { id: extruderMenuGroup; }

            orientation: ListView.Horizontal

            model: Cura.ExtrudersModel { id: extrudersModel; }

            Connections
            {
                target: Cura.MachineManager
                onGlobalContainerChanged: forceActiveFocus() // Changing focus applies the currently-being-typed values so it can change the displayed setting values.
            }

            delegate: Button
            {
                height: ListView.view.height
                width: Math.round(ListView.view.width / extrudersModel.rowCount())

                text: model.name
                tooltip: model.name
                exclusiveGroup: extruderMenuGroup
                checked: base.currentExtruderIndex == index

                onClicked:
                {
                    forceActiveFocus() // Changing focus applies the currently-being-typed values so it can change the displayed setting values.
                    Cura.ExtruderManager.setActiveExtruderIndex(index);
                }

                style: ButtonStyle
                {
                    background: Item
                    {
                        Rectangle
                        {
                            anchors.fill: parent
                            border.width: control.checked ? UM.Theme.getSize("default_lining").width * 2 : UM.Theme.getSize("default_lining").width
                            border.color: (control.checked || control.pressed) ? UM.Theme.getColor("action_button_active_border") :
                                          control.hovered ? UM.Theme.getColor("action_button_hovered_border") :
                                          UM.Theme.getColor("action_button_border")
                            color: (control.checked || control.pressed) ? UM.Theme.getColor("action_button_active") :
                                   control.hovered ? UM.Theme.getColor("action_button_hovered") :
                                   UM.Theme.getColor("action_button")
                            Behavior on color { ColorAnimation { duration: 50; } }
                        }

                        Item
                        {
                            id: extruderButtonFace
                            anchors.centerIn: parent
                            width: {
                                var extruderTextWidth = extruderStaticText.visible ? extruderStaticText.width : 0;
                                var iconWidth = extruderIconItem.width;
                                return Math.round(extruderTextWidth + iconWidth + UM.Theme.getSize("default_margin").width / 2);
                            }

                            // Static text "Extruder"
                            Label
                            {
                                id: extruderStaticText
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left

                                color: (control.checked || control.pressed) ? UM.Theme.getColor("action_button_active_text") :
                                       control.hovered ? UM.Theme.getColor("action_button_hovered_text") :
                                       UM.Theme.getColor("action_button_text")

                                font: UM.Theme.getFont("default")
                                text: catalog.i18nc("@label", "Extruder")
                                visible: width < (control.width - extruderIconItem.width - UM.Theme.getSize("default_margin").width)
                                elide: Text.ElideRight
                            }

                            // Everthing for the extruder icon
                            Item
                            {
                                id: extruderIconItem
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right

                                property var sizeToUse:
                                {
                                    var minimumWidth = control.width < UM.Theme.getSize("button").width ? control.width : UM.Theme.getSize("button").width;
                                    var minimumHeight = control.height < UM.Theme.getSize("button").height ? control.height : UM.Theme.getSize("button").height;
                                    var minimumSize = minimumWidth < minimumHeight ? minimumWidth : minimumHeight;
                                    minimumSize -= Math.round(UM.Theme.getSize("default_margin").width / 2);
                                    return minimumSize;
                                }

                                width: sizeToUse
                                height: sizeToUse

                                Label
                                {
                                    id: extruderNumberText
                                    anchors.centerIn: parent
                                    text: index + 1;
                                    color: (control.checked || control.pressed) ? UM.Theme.getColor("action_button_active_text") :
                                           control.hovered ? UM.Theme.getColor("action_button_hovered_text") :
                                           UM.Theme.getColor("action_button_text")
                                    font: UM.Theme.getFont("default_bold")
                                    renderType: Text.NativeRendering
                                }

                                // Material colour circle
                                // Only draw the filling colour of the material inside the SVG border.
                                Rectangle
                                {
                                    id: materialColorCircle

                                    anchors
                                    {
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        rightMargin: - parent.sizeToUse
                                    }

                                    color: model.color

                                    border.width: UM.Theme.getSize("default_lining").width
                                    border.color: UM.Theme.getColor("setting_control_border")

                                    height: Math.round(UM.Theme.getSize("setting_control").height / 2)
                                    width: height
                                    radius: Math.round(width / 2)

                                    opacity: !control.checked ? 0.6 : 1.0
                                }
                            }
                        }
                    }
                    label: Item {}
                }
            }
        }
    }

    Item
    {
        id: extruderRowSpacer
        height: Math.round(UM.Theme.getSize("default_margin").height / 4)
        width: height
        visible: !extruderSelectionRow.visible
    }

    //Variant & material row
    Item
    {
        id: variantRow
        height: UM.Theme.getSize("sidebar_setup").height
        visible: (Cura.MachineManager.hasVariants || Cura.MachineManager.hasMaterials)  && !sidebar.hideSettings

        anchors
        {
            left: parent.left
            leftMargin: UM.Theme.getSize("sidebar_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("sidebar_margin").width
        }

        Label
        {
            id: variantLabel
            anchors.verticalCenter: materialVariantContainer.verticalCenter
            width: Math.round(parent.width * 0.3)
            font: UM.Theme.getFont("default")
            color: UM.Theme.getColor("text")
            text:
            {
                var label;
                if(Cura.MachineManager.hasVariants && Cura.MachineManager.hasMaterials)
                {
                    label = "%1 & %2".arg(Cura.MachineManager.activeDefinitionVariantsName).arg(catalog.i18nc("@label","Material"));
                }
                else if(Cura.MachineManager.hasVariants)
                {
                    label = Cura.MachineManager.activeDefinitionVariantsName;
                }
                else
                {
                    label = catalog.i18nc("@label","Material");
                }
                return "%1:".arg(label);
            }
        }

        Item
        {
            id: materialVariantContainer

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right

            width: Math.floor(parent.width * 0.55 + UM.Theme.getSize("sidebar_margin").width)
            height: UM.Theme.getSize("setting_control").height

            ToolButton {
                id: variantSelection
                text: Cura.MachineManager.activeVariantName
                tooltip: Cura.MachineManager.activeVariantName;
                visible: Cura.MachineManager.hasVariants

                height: UM.Theme.getSize("setting_control").height
                width: materialSelection.visible ? Math.floor((parent.width - UM.Theme.getSize("default_margin").width) / 2) : parent.width
                anchors.left: parent.left
                style: UM.Theme.styles.sidebar_header_button
                activeFocusOnPress: true

                menu: Cura.NozzleMenu { extruderIndex: base.currentExtruderIndex }
            }

            ToolButton
            {
                id: materialSelection

                text: Cura.MachineManager.activeMaterialName
                tooltip: Cura.MachineManager.activeMaterialName
                visible: Cura.MachineManager.hasMaterials

                enabled: !extrudersList.visible || base.currentExtruderIndex  > -1

                height: UM.Theme.getSize("setting_control").height
                width: variantSelection.visible ? Math.floor((parent.width - UM.Theme.getSize("default_margin").width) / 2) : parent.width
                anchors.right: parent.right
                style: UM.Theme.styles.sidebar_header_button
                activeFocusOnPress: true

                menu: Cura.MaterialMenu { extruderIndex: base.currentExtruderIndex }

                property var valueError: !isMaterialSupported()
                property var valueWarning: ! Cura.MachineManager.isActiveQualitySupported

                function isMaterialSupported () {
                    return Cura.ContainerManager.getContainerMetaDataEntry(Cura.MachineManager.activeMaterialId, "compatible") == "True"
                }
            }
        }
    }

    UM.SettingPropertyProvider
    {
        id: machineExtruderCount

        containerStackId: Cura.MachineManager.activeMachineId
        key: "machine_extruder_count"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }

    UM.I18nCatalog { id: catalog; name:"cura" }
}
