#!/usr/bin/python

from __future__ import print_function


def format_color_string(string, style=None):
    if style == None:
        return string
    if not (style.has_key('mode') or style.has_key('fore') or style.has_key('back') or style.has_key('end')):
        return string
    mode = '%s' % style['mode'] if style.has_key('mode') else ''
    fore = '%s' % style['fore'] if style.has_key('fore') else ''
    back = '%s' % style['back'] if style.has_key('back') else ''
    end = '\033[%sm' % style['end'] if style.has_key('end') else ''
    color_style = ';'.join([s for s in [mode, fore, back] if s])
    color_style = '\033[%sm' % color_style if color_style else ''

    return '%s%s%s' % (color_style, string, end)


def xprint_new_line(text=None, style=None):
    print ('\r')
    print ('\r', end='')
    if text:
        print (format_color_string(text, style))


def xprint_head(text, style=None):
    print ('\r', end='')
    print (format_color_string(text, style))


def xprint_same_line(text, style=None):
    print (format_color_string(text, style), end='')


def xprint(text, style=None):
    print (format_color_string(text, style))
