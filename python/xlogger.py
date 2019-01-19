import logging
import sys
import os

LOGGER_DIRECTORY = sys.path[0] + '/data/'
LOGGER_FILE = sys.argv[0][sys.argv[0].rfind(os.sep) + 1:].split('.')[0] + '.log'
if not os.path.exists(LOGGER_DIRECTORY):
    os.makedirs(LOGGER_DIRECTORY)

xlogger = logging.getLogger(__name__)
xlogger.setLevel(level=logging.DEBUG)
xhandler = logging.FileHandler(LOGGER_DIRECTORY + LOGGER_FILE)
xhandler.setLevel(logging.DEBUG)
xformatter = logging.Formatter('%(asctime)s [%(levelname)s] %(filename)s:%(lineno)s - %(message)s')
xhandler.setFormatter(xformatter)
xlogger.addHandler(xhandler)
