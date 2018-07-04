# Copyright (c) 2018 fieldOfView
# The PrepareStageCompactor is released under the terms of the AGPLv3 or higher.

import os.path
from UM.Application import Application
from UM.Extension import Extension
from UM.Resources import Resources

from PyQt5.QtCore import QUrl

class PrepareStageCompactor(Extension):

    def __init__(self):
        super().__init__()

        Application.getInstance().engineCreatedSignal.connect(self._engineCreated)

    def _engineCreated(self):
        setting_items_path = QUrl.fromLocalFile( os.path.abspath((os.path.join(Resources.getPath(Application.getInstance().ResourceTypes.QmlFiles), "Settings"))) + "/")
        try:
            engine = Application.getInstance()._qml_engine
        except AttributeError:
            engine = Application.getInstance()._engine
        engine.rootContext().setContextProperty("prepareStageCompactorSettingItemsPath", setting_items_path)

        sidebar_component_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Sidebar.qml")
        prepare_stage = Application.getInstance().getController().getStage("PrepareStage")
        prepare_stage.addDisplayComponent("sidebar", sidebar_component_path)
