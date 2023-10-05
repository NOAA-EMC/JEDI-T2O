#!/bin/bash
# run_job.sh
# using rocotoboot, point to a global-workflow experiment
# and run a specified job for a specified cycle

usage() {
  set +x
  echo
  echo "Usage: $0 [-c] [-b] [-s]"
  echo
  echo "  -c  clone necessary repositories"
  echo "  -b  build GDASApp and GSI"
  echo "  -s  setup default experiment"
  echo "  -h  display this message and quit"
  echo
  exit 1
}

clone=NO
build=NO
setup=NO

while getopts "cbsh" opt; do
  case $opt in
    c)
      clone=YES
      ;;
    b)
      build=YES
      ;;
    s)
      setup=YES
      ;;
    h|\?|:)
      usage
      ;;
  esac
done

