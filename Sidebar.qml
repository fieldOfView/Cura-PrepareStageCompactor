// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

import UM 1.2 as UM
import Cura 1.0 as Cura

Rectangle
{
    id: base

    property bool hideSettings: PrintInformation.preSliced
    property bool hideView: Cura.MachineManager.activeMachineName == ""

    // Is there an output device for this printer?
    property bool isNetworkPrinter: Cura.MachineManager.activeMachineNetworkKey != ""
    property bool printerConnected: Cura.MachineManager.printerConnected
    property bool printerAcceptsCommands: printerConnected && Cura.MachineManager.printerOutputDevices[0].acceptsCommands
    property var connectedPrinter: Cura.MachineManager.printerOutputDevices.length >= 1 ? Cura.MachineManager.printerOutputDevices[0] : null

    property variant printDuration: PrintInformation.currentPrintTime
    property variant printMaterialLengths: PrintInformation.materialLengths
    property variant printMaterialWeights: PrintInformation.materialWeights
    property variant printMaterialCosts: PrintInformation.materialCosts
    property variant printMaterialNames: PrintInformation.materialNames

    property int currentModeIndex
    onCurrentModeIndexChanged:
    {
        UM.Preferences.setValue("cura/active_mode", currentModeIndex);
        if(modesListModel.count > base.currentModeIndex)
        {
            sidebarContents.replace(modesListModel.get(base.currentModeIndex).item, { "replace": true })
        }
    }

    color: UM.Theme.getColor("sidebar")
    UM.I18nCatalog { id: catalog; name:"cura"}

    Timer {
        id: tooltipDelayTimer
        interval: 500
        repeat: false
        property var item
        property string text

        onTriggered:
        {
            base.showTooltip(base, {x: 0, y: item.y}, text);
        }
    }

    function showTooltip(item, position, text)
    {
        tooltip.text = text;
        position = item.mapToItem(base, position.x - UM.Theme.getSize("default_arrow").width, position.y);
        tooltip.show(position);
    }

    function hideTooltip()
    {
        tooltip.hide();
    }

    function strPadLeft(string, pad, length) {
        return (new Array(length + 1).join(pad) + string).slice(-length);
    }

    function getPrettyTime(time)
    {
        var hours = Math.floor(time / 3600)
        time -= hours * 3600
        var minutes = Math.floor(time / 60);
        time -= minutes * 60
        var seconds = Math.floor(time);

        var finalTime = strPadLeft(hours, "0", 2) + ':' + strPadLeft(minutes,'0',2)+ ':' + strPadLeft(seconds,'0',2);
        return finalTime;
    }

    MouseArea
    {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons

        onWheel:
        {
            wheel.accepted = true;
        }
    }

    Cura.MachineSelection
    {
        id: machineSelection
        width: Math.round(base.width * 0.65 + UM.Theme.getSize("default_margin").width / 2) - configSelection.width
        height: UM.Theme.getSize("sidebar_header").height
        anchors.top: base.top
        anchors.left: parent.left
    }

    Cura.ConfigurationSelection
    {
        id: configSelection
        visible: isNetworkPrinter && printerConnected
        width: visible ? Math.round(base.width * 0.15) : 0
        height: UM.Theme.getSize("sidebar_header").height
        anchors.top: base.top
        anchors.left: machineSelection.right
        panelWidth: base.width
    }

    ModeSelection
    {
        id: sidebarModeButton

        height: UM.Theme.getSize("sidebar_header").height
        width: Math.round(base.width * 0.35 - UM.Theme.getSize("default_margin").width / 2)

        anchors {
            top: base.top
            right: parent.right
        }

        model: modesListModel
        onCurrentIndexChanged:
        {
            base.currentModeIndex = currentIndex;
        }
    }

    SidebarHeader {
        id: header
        width: parent.width
        visible: !hideSettings && (machineExtruderCount.properties.value > 1 || Cura.MachineManager.hasMaterials || Cura.MachineManager.hasVariants)
        anchors.top: machineSelection.bottom
        anchors.topMargin: UM.Theme.getSize("default_margin").height

        onShowTooltip: base.showTooltip(item, location, text)
        onHideTooltip: base.hideTooltip()
    }

    StackView
    {
        id: sidebarContents

        anchors.bottom: footerSeparator.top
        anchors.top: header.bottom
        anchors.topMargin: UM.Theme.getSize("default_margin").height
        anchors.left: base.left
        anchors.right: base.right
        visible: !hideSettings

        replaceEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to:1
                duration: 100
            }
        }

        replaceExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to:0
                duration: 100
            }
        }
    }

    Rectangle
    {
        id: footerSeparator
        width: parent.width
        height: UM.Theme.getSize("sidebar_lining").height
        color: UM.Theme.getColor("sidebar_lining")
        anchors.bottom: printSpecs.top
        anchors.bottomMargin: Math.round(UM.Theme.getSize("sidebar_margin").height * 2 + UM.Theme.getSize("progressbar").height + UM.Theme.getFont("default_bold").pixelSize)
    }

    Item
    {
        id: printSpecs
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: UM.Theme.getSize("sidebar_margin").width
        anchors.bottomMargin: UM.Theme.getSize("sidebar_margin").height
        height: timeDetails.height + costSpec.height
        width: base.width - (saveButton.buttonRowWidth + UM.Theme.getSize("sidebar_margin").width)
        clip: true

        Label
        {
            id: timeDetails
            anchors.left: parent.left
            anchors.bottom: costSpec.top
            font: UM.Theme.getFont("large")
            color: UM.Theme.getColor("text_subtext")
            text: (!base.printDuration || !base.printDuration.valid) ? catalog.i18nc("@label Hours and minutes", "00h 00min") : base.printDuration.getDisplayString(UM.DurationFormat.Short)
            renderType: Text.NativeRendering

            MouseArea
            {
                id: timeDetailsMouseArea
                anchors.fill: parent
                hoverEnabled: true

                onEntered:
                {
                    if(base.printDuration.valid && !base.printDuration.isTotalDurationZero)
                    {
                        // All the time information for the different features is achieved
                        var print_time = PrintInformation.getFeaturePrintTimes();
                        var total_seconds = parseInt(base.printDuration.getDisplayString(UM.DurationFormat.Seconds))

                        // A message is created and displayed when the user hover the time label
                        var tooltip_html = "<b>%1</b><br/><table width=\"100%\">".arg(catalog.i18nc("@tooltip", "Time specification"));
                        for(var feature in print_time)
                        {
                            if(!print_time[feature].isTotalDurationZero)
                            {
                                tooltip_html += "<tr><td>" + feature + ":</td>" +
                                    "<td align=\"right\" valign=\"bottom\">&nbsp;&nbsp;%1</td>".arg(print_time[feature].getDisplayString(UM.DurationFormat.ISO8601).slice(0,-3)) +
                                    "<td align=\"right\" valign=\"bottom\">&nbsp;&nbsp;%1%</td>".arg(Math.round(100 * parseInt(print_time[feature].getDisplayString(UM.DurationFormat.Seconds)) / total_seconds)) +
                                    "</td></tr>";
                            }
                        }
                        tooltip_html += "</table>";

                        base.showTooltip(parent, Qt.point(-UM.Theme.getSize("sidebar_margin").width, 0), tooltip_html);
                    }
                }
                onExited:
                {
                    base.hideTooltip();
                }
            }
        }

        Label
        {
            function formatRow(items)
            {
                var row_html = "<tr>";
                for(var item = 0; item < items.length; item++)
                {
                    if (item == 0)
                    {
                        row_html += "<td valign=\"bottom\">%1</td>".arg(items[item]);
                    }
                    else
                    {
                        row_html += "<td align=\"right\" valign=\"bottom\">&nbsp;&nbsp;%1</td>".arg(items[item]);
                    }
                }
                row_html += "</tr>";
                return row_html;
            }

            function getSpecsData()
            {
                var lengths = [];
                var total_length = 0;
                var weights = [];
                var total_weight = 0;
                var costs = [];
                var total_cost = 0;
                var some_costs_known = false;
                var names = [];
                if(base.printMaterialLengths)
                {
                    for(var index = 0; index < base.printMaterialLengths.length; index++)
                    {
                        if(base.printMaterialLengths[index] > 0)
                        {
                            names.push(base.printMaterialNames[index]);
                            lengths.push(base.printMaterialLengths[index].toFixed(2));
                            weights.push(String(Math.round(base.printMaterialWeights[index])));
                            var cost = base.printMaterialCosts[index] == undefined ? 0 : base.printMaterialCosts[index].toFixed(2);
                            costs.push(cost);
                            if(cost > 0)
                            {
                                some_costs_known = true;
                            }

                            total_length += base.printMaterialLengths[index];
                            total_weight += base.printMaterialWeights[index];
                            total_cost += base.printMaterialCosts[index];
                        }
                    }
                }
                if(lengths.length == 0)
                {
                    lengths = ["0.00"];
                    weights = ["0"];
                    costs = ["0.00"];
                }

                var tooltip_html = "<b>%1</b><br/><table width=\"100%\">".arg(catalog.i18nc("@label", "Cost specification"));
                for(var index = 0; index < lengths.length; index++)
                {
                    tooltip_html += formatRow([
                        "%1:".arg(names[index]),
                        catalog.i18nc("@label m for meter", "%1m").arg(lengths[index]),
                        catalog.i18nc("@label g for grams", "%1g").arg(weights[index]),
                        "%1&nbsp;%2".arg(UM.Preferences.getValue("cura/currency")).arg(costs[index]),
                    ]);
                }
                if(lengths.length > 1)
                {
                    tooltip_html += formatRow([
                        catalog.i18nc("@label", "Total:"),
                        catalog.i18nc("@label m for meter", "%1m").arg(total_length.toFixed(2)),
                        catalog.i18nc("@label g for grams", "%1g").arg(Math.round(total_weight)),
                        "%1 %2".arg(UM.Preferences.getValue("cura/currency")).arg(total_cost.toFixed(2)),
                    ]);
                }
                tooltip_html += "</table>";
                tooltipText = tooltip_html;

                return tooltipText
            }

            id: costSpec
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            font: UM.Theme.getFont("very_small")
            renderType: Text.NativeRendering
            color: UM.Theme.getColor("text_subtext")
            elide: Text.ElideMiddle
            width: parent.width
            property string tooltipText
            text:
            {
                var lengths = [];
                var weights = [];
                var costs = [];
                var someCostsKnown = false;
                if(base.printMaterialLengths) {
                    for(var index = 0; index < base.printMaterialLengths.length; index++)
                    {
                        if(base.printMaterialLengths[index] > 0)
                        {
                            lengths.push(base.printMaterialLengths[index].toFixed(2));
                            weights.push(String(Math.round(base.printMaterialWeights[index])));
                            var cost = base.printMaterialCosts[index] == undefined ? 0 : base.printMaterialCosts[index].toFixed(2);
                            costs.push(cost);
                            if(cost > 0)
                            {
                                someCostsKnown = true;
                            }
                        }
                    }
                }
                if(lengths.length == 0)
                {
                    lengths = ["0.00"];
                    weights = ["0"];
                    costs = ["0.00"];
                }
                var result = lengths.join(" + ") + "m / ~ " + weights.join(" + ") + "g";
                if(someCostsKnown)
                {
                    result += " / ~ " + costs.join(" + ") + " " + UM.Preferences.getValue("cura/currency");
                }
                return result;
            }
            MouseArea
            {
                id: costSpecMouseArea
                anchors.fill: parent
                hoverEnabled: true

                onEntered:
                {

                    if(base.printDuration.valid && !base.printDuration.isTotalDurationZero)
                    {
                        var show_data = costSpec.getSpecsData()

                        base.showTooltip(parent, Qt.point(-UM.Theme.getSize("sidebar_margin").width, 0), show_data);
                    }
                }
                onExited:
                {
                    base.hideTooltip();
                }
            }
        }
    }

    Cura.SaveButton
    {
        id: saveButton
        implicitWidth: base.width
        anchors.top: footerSeparator.bottom
        anchors.topMargin: UM.Theme.getSize("sidebar_margin").height
        anchors.bottom: parent.bottom
    }

    Cura.SidebarTooltip
    {
        id: tooltip
    }

    // Setting mode: Recommended or Custom
    ListModel
    {
        id: modesListModel
    }

    Cura.SidebarSimple
    {
        id: sidebarSimple
        visible: false

        onShowTooltip: base.showTooltip(item, location, text)
        onHideTooltip: base.hideTooltip()
    }

    SettingView
    {
        id: sidebarAdvanced
        visible: false

        onShowTooltip: base.showTooltip(item, location, text)
        onHideTooltip: base.hideTooltip()
    }

    Component.onCompleted:
    {
        modesListModel.append({
            text: catalog.i18nc("@title:tab", "Recommended"),
            tooltipText: catalog.i18nc("@tooltip", "<b>Recommended Print Setup</b><br/><br/>Print with the recommended settings for the selected printer, material and quality."),
            item: sidebarSimple
        })
        modesListModel.append({
            text: catalog.i18nc("@title:tab", "Custom"),
            tooltipText: catalog.i18nc("@tooltip", "<b>Custom Print Setup</b><br/><br/>Print with finegrained control over every last bit of the slicing process."),
            item: sidebarAdvanced
        })
        sidebarContents.replace(modesListModel.get(base.currentModeIndex).item, { "immediate": true })

        var index = Math.round(UM.Preferences.getValue("cura/active_mode"))
        if(index != null && !isNaN(index))
        {
            currentModeIndex = index;
        }
        else
        {
            currentModeIndex = 0;
        }
    }

    UM.SettingPropertyProvider
    {
        id: machineExtruderCount

        containerStack: Cura.MachineManager.activeMachine
        key: "machine_extruder_count"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }

    UM.SettingPropertyProvider
    {
        id: machineHeatedBed

        containerStack: Cura.MachineManager.activeMachine
        key: "machine_heated_bed"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }
}
