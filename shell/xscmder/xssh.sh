#!/usr/bin/bash

:<<COMMENT
xssh_action = {
    'name': 'ssh',
    'sub_cmds': [
        {
            'name': 'login',
            'action': action_login,
        },
        {
            'name': 'check',
            'action': action_check,
        },
        {
            'name': 'remove',
            'action': action_remove,
        },
    ],
}
COMMENT