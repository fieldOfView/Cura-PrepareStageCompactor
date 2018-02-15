# Copyright (c) 2018 fieldOfView
# The PrepareStageCompactor is released under the terms of the AGPLv3 or higher.

from . import PrepareStageCompactor
from UM.i18n import i18nCatalog
i18n_catalog = i18nCatalog("cura")

def getMetaData():
	return {}

def register(app):
    return {
        "extension": PrepareStageCompactor.PrepareStageCompactor()
    }
