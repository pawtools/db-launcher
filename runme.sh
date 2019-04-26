#!/bin/bash


SHPROFILE="/gpfs/alpine/bif112/proj-shared/db-launcher/mongo.bashrc"
DBLOCATION="/gpfs/alpine/bif112/proj-shared/test-db-launcher/"
JOBNAME="testlaunch"

if ! [ -d "$DBLOCATION" ]
then
  mkdir $DBLOCATION
fi

bsub -J $JOBNAME -nnodes 1 -W 5 -P bif112 -env "all, SHPROFILE=$SHPROFILE, ARGS=$DBLOCATION" jobscript.lsf
