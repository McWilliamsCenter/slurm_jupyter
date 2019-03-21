#!/bin/bash

ssh -L 8888:localhost:8888 -t mho1@coma.hpc1.cs.cmu.edu "jupyter notebook"
