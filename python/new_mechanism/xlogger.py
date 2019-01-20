import logging
import sys
import os
from xdefine import XConst

if not os.path.exists(XConst.LOGGER_DIRECTORY):
    os.makedirs(XConst.LOGGER_DIRECTORY)

xlogger = logging.getLogger(__name__)
xlogger.setLevel(level=logging.DEBUG)
xhandler = logging.FileHandler(XConst.LOGGER_DIRECTORY + XConst.LOGGER_FILE)
xhandler.setLevel(logging.DEBUG)
xformatter = logging.Formatter('%(asctime)s [%(levelname)s] %(filename)s:%(lineno)s - %(message)s')
xhandler.setFormatter(xformatter)
xlogger.addHandler(xhandler)
