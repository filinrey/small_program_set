import os  
import sys
import tty, termios
import time    

print "Reading form keybord"
print 'press Q to quit'
while True:
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)  
    if ch == 'q':
        print "shutdown!"
        break
    elif ord(ch) == 0x3:
        print "ctrl c, shutdown"
        break
    elif ord(ch) == 0x09:
        print "tab key"
    else:
        print "key is %s (%x)" % (ch, ord(ch))

