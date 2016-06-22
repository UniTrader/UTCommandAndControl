#!/bin/bash
# param $1: X Rebirth Extensions Directory
if [ -d $1 ]; then
  for d in */; do
    ln -s $1 $d
  done
fi
