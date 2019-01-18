import logging
import sys

xlogger = logging.getLogger(__name__)
xlogger.setLevel(level=logging.DEBUG)
xhandler = logging.FileHandler(sys.path[0] + '/data/log')
xhandler.setLevel(logging.DEBUG)
xformatter = logging.Formatter('%(asctime)s [%(levelname)s] %(filename)s:%(lineno)s - %(message)s')
xhandler.setFormatter(xformatter)
xlogger.addHandler(xhandler)
