#!/usr/bin/env bash

BENCH_DIR=$PWD/bench

function echo_err(){
  echo $* >&2
}

function fetch_bench() {
  cd $BENCH_DIR; git fetch --all >/dev/null
}

function install_bench() {
  cd $BENCH_DIR; go install
}

function checkout_bench_ref() {
  git checkout $1 >/dev/null 2>&1
  if [ $? -ne 0 ];then
    echo_err "version $1 does not exist. Please use one of the following valid values:"
    cd $BENCH_DIR; git for-each-ref --format='%(refname:short)' refs/heads/
    cd $BENCH_DIR; git tag | grep -Pe "v\d+\.\d+\.\d+" | sort -rh
  fi
}

function entrypoint_help {
  echo "Container wrapper help:"
  echo "  get-bench-version             Shows the currently installed benchmark version and exits"
  echo "  set-bench-version [version]   Switches to the given version of the benchmark (can be a branch or tag)"
  echo "  set-bench-latest              Switches to the most up-to-date version of the benchmark"
  echo "  update                        Same as set-bench-latest"
  echo "  bash|sh                       Launches an interactive shell"
  echo "  *                             run all given text as an argument to ibench"
  printf "\n\n"
}

case $1 in

  get-bench-version)
    cd $BENCH_DIR; git symbolic-ref -q --short HEAD || git describe --tags --exact-match
    ;;
  set-bench-version)
    if [ $# -gt 2 ];then
      echo_err "Must specify a tag/branch to switch to or use 'set-bench-latest' to use the latest tag"
      exit 1
    fi
    fetch_bench
    checkout_bench_ref $2
    install_bench
    ;;


  set-bench-latest|update)
    fetch_bench
    checkout_bench_ref $(cd $BENCH_DIR; git tag | grep -Pe "v\d+\.\d+\.\d+" | sort -rh | head -n 1)
    install_bench
  ;;

  bash|sh)
    exec $@
  ;;

  help|--help)
    entrypoint_help
    ibench --help
  ;;

  *)
    ibench $@
  ;;
esac
