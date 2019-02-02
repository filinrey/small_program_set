#!/bin/bash
# arrow-detect.sh: 检测方向键, 和一些非打印字符的按键.
# 感谢, Sandro Magi, 告诉了我们怎么做到这点.

# --------------------------------------------
# 按键所产生的字符编码.
arrowup='\[A'
arrowdown='\[B'
arrowrt='\[C'
arrowleft='\[D'
insert='\[2'
delete='\[3'
tab='\\t'
# --------------------------------------------

SUCCESS=0
OTHER=65

while [ 1 ]
do
    echo "Press a key...  "
    # 如果不是上边列表所列出的按键, 可能还是需要按回车. (译者注: 因为一般按键是一个字符)
    read -s -n1 key
    echo "$key="
    
    #echo -n "$key" | grep "$tab"
    #if [ "$?" -eq $SUCCESS ]; then
    if [[ $key ==  ]]; then
        echo "esc key pressed."
    fi

    echo -n "$key" | grep "$arrowup"
    if [ "$?" -eq $SUCCESS ]; then
        echo "Up-arrow key pressed."
    fi

    echo -n "$key" | grep "$arrowdown"
    if [ "$?" -eq $SUCCESS ]; then
        echo "Down-arrow key pressed."
    fi

    echo -n "$key" | grep "$arrowrt"
    if [ "$?" -eq $SUCCESS ]; then
        echo "Right-arrow key pressed."
    fi

    echo -n "$key" | grep "$arrowleft"
    if [ "$?" -eq $SUCCESS ]; then
        echo "Left-arrow key pressed."
    fi

    echo -n "$key" | grep "$insert"
    if [ "$?" -eq $SUCCESS ]; then
        echo "\"Insert\" key pressed."
    fi

    echo -n "$key" | grep "$delete"
    if [ "$?" -eq $SUCCESS ]; then
        echo "\"Delete\" key pressed."
    fi

    #echo " Some other key pressed."
done
