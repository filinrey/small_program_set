#!/usr/bin/python

from __future__ import print_function
import os
import sys
import tty
import termios
import time

PYFILE_NAME = sys.argv[0][sys.argv[0].rfind(os.sep) + 1:]
PREFIX_NAME = PYFILE_NAME + "# "
PREFIX_SHOW = PREFIX_NAME

SUPPORT_CMD = ['login', 'log', 'show']
STATES = ['INPUT_CMD', 'SHOW_RECORD']
CURRENT_STATE = STATES[0]
INPUT_CMD = ''

def clear_line(length):
    print ("\r", end='')
    padding = length * ' '
    print (padding, end='')

def show_support_cmd():
    print ('\r')
    for cmd in SUPPORT_CMD:
        print ("\t", cmd)

print ('press Ctrl+C to quit')
while True:
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        print (PREFIX_SHOW, end='')
        ch = sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)  
    if ord(ch) == 0x3:
        # ctrl + c key
        print ("ctrl c, shutdown")
        break
    elif ord(ch) == 0x09:
        # tab key
        if CURRENT_STATE == 'INPUT_CMD':
            show_support_cmd()
    elif ord(ch) == 0x7f:
        # backspace key
        if CURRENT_STATE == 'INPUT_CMD':
            INPUT_CMD = INPUT_CMD[0:-1]
            PREFIX_SHOW = PREFIX_NAME + INPUT_CMD
            clear_line(len(PREFIX_SHOW + " "))
        print ("\r", end='')
    elif ord(ch) == 0x0d:
        # return key
        print ("")
    elif ch.isalnum():
        if CURRENT_STATE == 'INPUT_CMD':
            INPUT_CMD = INPUT_CMD + ch
            PREFIX_SHOW = PREFIX_NAME + INPUT_CMD
        print ("\r", end='')
    else:
        print ("unshowed key is ", ord(ch))

