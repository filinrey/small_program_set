#!/usr/bin/python

from __future__ import print_function


def xprint_new_line(text=None):
    print ('\r')
    print ('\r', end='')
    if text:
        print (text)


def xprint_head(text):
    print ('\r', end='')
    print (text)
