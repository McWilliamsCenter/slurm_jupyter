#/bin/bash


read -p "Enter vera node: " node


ssh -N -L 8888:$node:8888 mho1@login.vera.psc.edu
