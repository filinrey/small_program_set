#!/usr/bin/python

from __future__ import print_function
import os
from xdefine import XKey, XConst, XPrintStyle
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, xprint_same_line, xprint


def show_install_help():
    xprint_new_line('\t# install [PATH]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # install')
    xprint_head('\t           -> install ' + XConst.PYFILE_NAME + ' in /usr/bin/ as default')
    xprint_head('\tExample 2: # install /bin')
    xprint_head('\t           -> install ' + XConst.PYFILE_NAME + ' in /bin')


def install_myself(install_dir):
    link_name = install_dir + '/' + XConst.PYFILE_NAME
    system_command = 'sudo rm -f ' + link_name
    os.system(system_command)
    system_command = 'sudo ln -s ' + XConst.REPO_DIR + '/' + XConst.PYFILE_WHOLE + ' ' + link_name
    os.system(system_command)
    xprint('{} : successful'.format(link_name))
    exit()


def action_install(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    install_dir = '/usr/bin'
    if num_cmd == 1:
        if not os.path.exists(cmds[0]):
            xprint_new_line('\t' + cmds[0] + ' is not exists')
            return {'flag': True, 'new_input_cmd': ''}
        install_dir = cmds[0]
    if key == XKey.ENTER and num_cmd <= 1:
        xprint_new_line()
        xprint_same_line('\tinstalling ')
        install_myself(install_dir)
        return {'flag': True, 'new_input_cmd': ''}

    show_install_help()


xinstall_action = {
    'name': 'install',
    'active': True,
    'action': action_install,
}
