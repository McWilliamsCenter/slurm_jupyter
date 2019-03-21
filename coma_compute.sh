#/bin/bash


read -p "Enter coma node: " node


ssh -N -L 8888:$node:8888 mho1@coma.hpc1.cs.cmu.edu
