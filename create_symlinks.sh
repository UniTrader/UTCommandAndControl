#!/bin/bash
# param $1: X Rebirth Extensions Directory
#if [ -d $1 ]; then
  for d in ./*/; do
    ln -s "$PWD/$d" "$1"
  done
#fi
