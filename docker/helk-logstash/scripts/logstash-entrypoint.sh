#!/bin/bash

# HELK script: logstash-entrypoint.sh
# HELK script description: Pushes output templates to ES and starts Logstash
# HELK build Stage: Alpha
# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0


logstash-plugin install logstash-input-kafka && logstash-plugin install logstash-output-s3

# ********* Setting LS_JAVA_OPTS ***************
if [[ -z "$LS_JAVA_OPTS" ]]; then
  while true; do
    # Check using more accurate MB
    AVAILABLE_MEMORY=$(awk '/MemAvailable/{printf "%.f", $2/1024}' /proc/meminfo)
    if [ $AVAILABLE_MEMORY -ge 900 -a $AVAILABLE_MEMORY -le 1000 ]; then
      LS_MEMORY=400
      LS_MEMORY_HIGH=1000
      export LS_JAVA_OPTS="-Xms${LS_MEMORY}m -Xmx${LS_MEMORY_HIGH}m"
      break
    elif [ $AVAILABLE_MEMORY -ge 1001 -a $AVAILABLE_MEMORY -le 3000 ]; then
      LS_MEMORY=700
      LS_MEMORY_HIGH=1300
      export LS_JAVA_OPTS="-Xms${LS_MEMORY}m -Xmx${LS_MEMORY_HIGH}m"
      break
    elif [ $AVAILABLE_MEMORY -gt 3000 ]; then
      # Set high & low, so logstash doesn't use everything unnecessarily, it will usually flux up and down in usage -- and doesn't "severely" despite what everyone seems to believe
      LS_MEMORY=$(( AVAILABLE_MEMORY / 4 ))
      LS_MEMORY_HIGH=$(( AVAILABLE_MEMORY / 2 ))
      if [ $AVAILABLE_MEMORY -gt 31000 ]; then
        LS_MEMORY=8000
        LS_MEMORY_HIGH=31000
      fi
      export LS_JAVA_OPTS="-Xms${LS_MEMORY}m -Xmx${LS_MEMORY_HIGH}m"
      break
    else
      echo "[HELK-LOGSTASH-DOCKER-INSTALLATION-INFO] $LS_MEMORY MB is not enough memory for Logstash yet.."
      sleep 1
    fi
  done
fi
echo "[HELK-LOGSTASH-DOCKER-INSTALLATION-INFO] Setting LS_JAVA_OPTS to $LS_JAVA_OPTS"

# ********** Starting Logstash *****************
echo "[HELK-LOGSTASH-DOCKER-INSTALLATION-INFO] Running docker-entrypoint script.."
/usr/local/bin/docker-entrypoint