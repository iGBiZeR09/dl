#!/bin/bash
echo "deb https://mirror.sg.gs/debian/ trixie main" > /etc/apt/sources.list.d/nala-trixie.list
echo "deb https://mirror.twds.com.tw/debian/ trixie main" >> /etc/apt/sources.list.d/nala-trixie.list

chmod +777 /etc/apt/sources.list.d/nala-trixie.list
