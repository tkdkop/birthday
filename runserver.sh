#!/bin/bash

python2 -m SimpleHTTPServer 4000 &
coffee -o js  -w coffee/* &
