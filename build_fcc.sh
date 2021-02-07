#!/bin/sh

BIN=./fcct-x86_64-unknown-linux-gnu

download()  { 
    wget https://github.com/coreos/fcct/releases/download/v0.7.0/fcct-x86_64-unknown-linux-gnu
    chmod +x $BIN
}


echo $1


[ -f $BIN ] || download

$BIN $1 -o $2
