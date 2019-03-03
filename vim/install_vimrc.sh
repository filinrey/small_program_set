#!/usr/bin/bash

echo "download Vundle.vim to $HOME/.vim/bundle/"
mkdir -p ~/.vim/bundle/
git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim

cp ./vimrc ~/.vimrc
vim +PluginInstall +qall
