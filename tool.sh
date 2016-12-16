#!/bin/bash

##################################################
#                    Variables                   #
##################################################
version="0.0.2"
hasDepends=true
gitPath=$(which git 2>&1)
cmakePath=$(which cmake 2>&1)
ninjaPath=$(which ninja 2>&1)
distro=$(sed -n 3p /etc/os-release | sed 's/^...//')
cmakebuilddir=$(pwd)"/build-cmake-$distro"
cpucores=$(grep -c ^processor /proc/cpuinfo)


##################################################
#                    Functions                   #
##################################################
function dependCheck() {
  which git &>/dev/null
  hasGit=$?

  which cmake &>/dev/null
  hasCMake=$?

  which ninja &>/dev/null
  hasNinja=$?

  if [ $hasGit -ne 0 ]; then
    echo "Missing Git"
    hasDepends=false
  else
    echo "Path to Git: $gitPath"
  fi
  if [ $hasCMake -ne 0 ]; then
    echo "Missing CMake"
    hasDepends=false
  else
    echo "Path to CMake: $cmakePath"
  fi
  if [ $hasNinja -ne 0 ]; then
    echo "Missing Ninja"
    hasDepends=false
  else
    echo "Path to Ninja: $ninjaPath"
  fi

}

function generate() {
  mkdir -p "$cmakebuilddir"
  cd "$cmakebuilddir"
  $cmakepath -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DNPM_ENABLE=ON -G Ninja ../
}

function build() {
  cd "$cmakebuilddir"
  $ninjaPath -j$cpucores
}

function clean() {
  rm -rf "$cmakebuilddir"
  #rm -rf main.c
}

function gitAdd() {
  $gitPath add $1
}

function gitCommit() {
  $gitPath commit -am "$@"
}

function gitPush() {
  $gitPath push
}

function cleanAndBuild() {
  echo "Cleaning..."
  clean
  echo "Generating..."
  generate
  echo "Building..."
  build
  exit 0
}

function gitCommitAndPush() {
  echo "Committing..."
  gitCommit "$@"
  echo "Pushing..."
  gitPush
}


##################################################
#                    Arguments                   #
##################################################
if [ $# -le 0 ]; then
  echo "No arguments"
  echo ""
  echo "Use 'help' to list available arguments"
  echo "Exiting..."
  exit 1
fi

if [ $# -eq 1 ]; then
  if [ $1 = "gen" ]; then
    echo 'Generating...'
    generate
    exit 0
  fi
  if [ $1 = "build" ]; then
    echo 'Generating...'
    generate
    echo 'Building...'
    build
    exit 0
  fi
  if [ $1 = "clean" ]; then
    echo "Cleaning..."
    clean
    exit 0
  fi
  if [ $1 = "cab" ]; then
    cleanandbuild
    exit 0
  fi
  if [ $1 = "depends" ]; then
    echo "Checking Dependencies..."
    dependCheck
    if [ $hasDepends = true ]; then
      echo "All dependencies installed"
      exit 0
    else
      echo "Some dependencies are missing."
      echo "See above about which"
      exit 1
    fi
  fi
  if [ $1 = "push" ]; then
    echo "Pushing..."
    gitPush
    exit 0
  fi
  if [ $1 = "help" ]; then
    echo "################################################################################"
    echo "#                                    Usage:                                    #"
    echo "################################################################################"
    echo ""
    echo ""
    echo "################################################################################"
    echo "#                                     Misc                                     #"
    echo "################################################################################"
    echo ""
    echo "'depends': Check if all dependencies are installed"
    echo "'help': Show this message"
    echo "'version': Output version information"
    echo ""
    echo ""
    echo "################################################################################"
    echo "#                                   Building                                   #"
    echo "################################################################################"
    echo ""
    echo "'build': Build"
    echo "'gen': Generate"
    echo ""
    echo ""
    echo "################################################################################"
    echo "#                                  Maintenance                                 #"
    echo "################################################################################"
    echo ""
    echo "'clean': Clean"
    echo ""
    echo ""
    echo "################################################################################"
    echo "#                                      Git                                     #"
    echo "################################################################################"
    echo ""
    echo "'add': Add the specified files"
    echo "'commit': Commit tracked files"
    echo "'push': Push pending commits"
    echo ""
    echo ""
    echo "################################################################################"
    echo "#                                Joint Commands                                #"
    echo "################################################################################"
    echo ""
    echo "'cab': Clean and Build"
    echo "'cap': Commit and Push"
    echo ""
    echo ""
    echo "################################################################################"
    echo "#                                     Notes                                    #"
    echo "################################################################################"
    echo ""
    echo "Generation is automatically done when building"
    echo ""
    echo ""
    exit 0
  fi
  if [ $1 = "version" ]; then
    echo "tool.sh version $version"
    exit 0
  fi
  echo "Unknown argument $1"
  echo ""
  echo "Use 'help' to list available arguments"
  echo "Exiting..."
  exit 1
fi

if [ $# -eq 2 ]; then
  if [ $1 = "commit" ]; then
    echo "Committing..."
    1=""
    2=""
    echo "$@"
    gitCommit "${@:2}"
    exit 0
  fi
  if [ $1 = "cap" ]; then
    gitCommitAndPush "${@:2}"
    exit 0
  fi
  if [ $1 != "add" ]; then
    echo "Unknown argument $1, $2"
    echo ""
    echo "Use 'help' to list available arguments"
    echo "Exiting..."
    exit 1
  fi
fi

if [ $# -ge 2 ]; then
  if [ $1 = "add" ]; then
    echo "Adding Specified Files..."
    echo ""
    for (( i=2; i<=$#; i++ )); do
      echo "Adding ${!i}..."
      gitAdd ${!i}
    done
    exit 0
  fi
  echo "Unknown arguments"
  echo ""
  echo "Use 'help' to list available arguments"
  echo "Exiting..."
  exit 1
fi
