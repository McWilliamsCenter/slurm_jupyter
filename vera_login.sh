#!/bin/bash

ssh -L 8888:localhost:8888 -t mho1@login.vera.psc.edu "jupyter notebook"
