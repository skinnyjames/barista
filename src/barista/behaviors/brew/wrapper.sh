#!/bin/sh

safeinput=$1
pidfile=$2

eval "${safeinput} 2>&1 &"
pid=$!

echo $pid > $pidfile
echo $pid



