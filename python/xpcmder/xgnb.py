#!/usr/bin/python

from __future__ import print_function
import os
import re
from xdefine import XKey, XConst, XPrintStyle
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, format_color_string
from xgnb_cprt import action_gnb_cprt_sdk, action_gnb_cprt_build, action_gnb_cprt_ut, action_gnb_cprt_pytest
from xgnb_cu import action_gnb_cu_sdk, action_gnb_cu_build, action_gnb_cu_ut, action_gnb_cu_pytest
from xgnb_cpnrt import action_gnb_cpnrt_sdk, action_gnb_cpnrt_build, action_gnb_cpnrt_ut, action_gnb_cpnrt_pytest


xgnb_action = {
    'name': 'gnb',
    'sub_cmds':
    [
        {
            'name': 'cprt',
            'sub_cmds':
            [
                {
                    'name': 'sdk',
                    'action': action_gnb_cprt_sdk,
                },
                {
                    'name': 'build',
                    'action': action_gnb_cprt_build,
                },
                {
                    'name': 'ut',
                    'action': action_gnb_cprt_ut,
                },
                {
                    'name': 'pytest',
                    'action': action_gnb_cprt_pytest,
                },
            ],
        },
        {
            'name': 'cu',
            'sub_cmds':
            [
                {
                    'name': 'sdk',
                    'action': action_gnb_cu_sdk,
                },
                {
                    'name': 'build',
                    'action': action_gnb_cu_build,
                },
                {
                    'name': 'ut',
                    'action': action_gnb_cu_ut,
                },
                {
                    'name': 'pytest',
                    'action': action_gnb_cu_pytest,
                },
            ],
        },
        {
            'name': 'cpnrt',
            'sub_cmds':
            [
                {
                    'name': 'sdk',
                    'action': action_gnb_cpnrt_sdk,
                },
                {
                    'name': 'build',
                    'action': action_gnb_cpnrt_build,
                },
                {
                    'name': 'ut',
                    'action': action_gnb_cpnrt_ut,
                },
                {
                    'name': 'pytest',
                    'action': action_gnb_cpnrt_pytest,
                },
            ],
        },
    ],
}
