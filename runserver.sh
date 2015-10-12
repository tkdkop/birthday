#!/bin/bash

 python -m SimpleHTTPServer 4000 &
coffee --output js  --watch coffee/* &
