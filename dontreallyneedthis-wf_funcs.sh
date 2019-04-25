
# I left this in here to have a bsub example I use
# to launch the LSF jobs that launch DB, so you can
# search for the bsub. 
#
# --> 99-100% of this isn't really relevant for us
#     right now though


#-----------------------------------------------#
#  Shell functions used during the execution    #
#  of AdaptiveMD workflows. These are used by   #
#  multiple layers of our execution scheme      #
#-----------------------------------------------#

function checkpoint {
  echo "Did you prepare margs?"
  echo "How about correct database is live and connected if using RP?"
  echo "Typed in your workflow setup correctly?"
  read -t 1 -n 999999 discard 
  read -n 1 -p  " >>> Type \"y\" if ready to proceed: " proceedinput
  if [ "$proceedinput" = "y" ]
  then
    echo ""
    echo "Moving to next phase"
    return 0
  else
    exit 0
  fi
}


function waitfor {
  jobstate="NONE"
  echo "Waiting for AdaptiveMD workload in job #$1"
  if [ "$#" = "2" ]
  then
    if [ -f "$2" ]
    then
      echo "Looking in file $2 for job state updates"
    else
      echo "Error: Cannot find the given job state file $2"
      exit 1
      #return
    fi
  fi
  while [ "$jobstate" != "DONE" ] && [ "$jobstate" != "EXIT" ]
  do
    if [ "$#" = "2" ]
    then
      jobstate=$(cat "$2")
    else
      jobstate=$(bjobs "$1" | grep "$1" | awk '{for(i=1;i<NF+1;i++){if($i=="PEND"||$i=="RUN"||$i=="DONE"||$i=="EXIT"){print $i}}}')
    fi
    sleep 5
  done
  echo "AdaptiveMD workload in job #$1 has finished"
  return 0
}


function admd_exec {
  # args are:
  #       1          2          3     4       5        6        7
  # roundnumber projname wkloadtype ntask mdsteps tjsteps afterntjs
  #           8          9       10      11      12     13   14      15
  # anlyztjlength samplefunc minutes execflag sysname mfreq pgreq platform
  echo "Got these arguments for workload:"
  echo $@
  if [[ ${10} =~ ^[0-9]+$ ]]
  then
    echo "executing for ${10} minutes"
    echo "Using AdaptiveMDWorkers to Execute Workload"
    NNODES=$(( ($4 / 6) + 1 ))
    if [ "$(($4 % 6))" -gt "0" ]; then
        NNODES=$(($NNODES + 1))
    fi
    echo "Using $NNODES nodes to execute $4 tasks"
    WKLTYPE="$3"
    DLM=":"
    DBHOME=$(echo ${11} | awk -F"$DLM" '{print $1}')
    DBPORT=$(echo ${11} | awk -F"$DLM" '{print $2}')
    if [ -z "$DBPORT" ]
    then
      DBPORT="27017"
    fi
    echo "Starting database at $DBHOME on port $DBPORT"
    ADMD_DBURL="mongodb://$ADMD_HOSTNAME:$DBPORT/"
    MPID=$($ADMD_RUNTIME/launch_amongod.sh $DBHOME $DBPORT)
    sleep 10
    echo "Mongo DB process ID: $MPID"
    echo "Running AdaptiveMD Application:"
    appcommand="$ADMD_RUNTIME/application.sh $1 $2 $WKLTYPE $4 $5 $6 $7 $8 $9 ${10} --submit_only ${12} ${13} ${14} ${15}"
    APP_OUT=$(eval $appcommand)
    IFS=$'\n' APP_OUT=($APP_OUT)
    APP_STATUS="${APP_OUT[${#APP_OUT[@]}-1]}"
    echo "Got Status '$APP_STATUS' from AdaptiveMD"
    echo "killing Mongo DB"
    kill $MPID
    wait $MPID
    sleep 5
    if [ "$(ls -A $DBHOME/socket)" ]
    then
      rm $DBHOME/socket/*
      rm $DBHOME/db/mongod.lock
    fi
    if [[ $APP_STATUS =~ ^[-+]?([1-9][[:digit:]]*|0)$ ]]
    then
        if [[ $APP_STATUS -lt 0 ]]
        then
          echo "Exiting, AdaptiveMD application error"
          exit 1
        elif [[ $APP_STATUS -eq 0 ]]
        then
          echo "No incomplete/failed tasks, executing given workload"
        elif [[ $APP_STATUS -gt 0 ]]
        then
          echo "Exiting, found existing incomplete/failed tasks"
          exit 0
        else
          echo "This condition should not appear, already closed logic"
        fi
    else
        echo "Exiting, $APP_STATUS not castable as int"
        exit 1
    fi
    JOBSTATEFILE="admd.state"
    echo "PEND" > $JOBSTATEFILE

    submitcommand="bsub -J $2.$1.$WKLTYPE.admd -nnodes $NNODES -W ${10} -P bif112 -alloc_flags smt4 -env \"all, SHPROFILE=$ADMD_ACTIVATE, ARGS=$1*$2*cleanup*$4*$5*$6*$7*$8*$9*${10}*$DBHOME*$JOBSTATEFILE\" $ADMD_RUNTIME/exectasks.lsf"
    echo $submitcommand
    ADMD_JOBOUT=$(eval $submitcommand)
    ADMD_JOBID="${ADMD_JOBOUT//[!0-9]/}"
    echo "Initiated AdaptiveMD workload in job# $ADMD_JOBID"
    waitfor $ADMD_JOBID $JOBSTATEFILE
    JOB_STATUS="$?"
    rm $JOBSTATEFILE
  fi

  echo "AdaptiveMD Job Exit Status: $JOB_STATUS"
  if [ "$JOB_STATUS" != "0" ]
  then
    echo "Exiting, got Error from job status: $JOB_STATUS"
    exit 1
  fi

  echo "Moving output logs from last workload"
  #sh $ADMD_RUNTIME/send_logs.sh $(latest)
  bash $ADMD_RUNTIME/send_logs.sh
  echo "Workload is complete"
}


