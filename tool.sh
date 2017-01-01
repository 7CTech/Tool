#!/bin/bash

##################################################
#                    Variables                   #
##################################################
version="0.0.5"
hasDepends=true
gitPath=$(which git 2>&1)
cmakePath=$(which cmake 2>&1)
ninjaPath=$(which ninja 2>&1)
distro=$(sed -n 3p /etc/os-release | sed 's/^...//')
cmakeBuildDir=$(pwd)"/build-cmake-$distro"
cpuCores=$(grep -c ^processor /proc/cpuinfo)
rootDir=$(pwd)


##################################################
#                    Functions                   #
##################################################\
function dependencies() {
  which git &>/dev/null
  hasGit=$?

  which cmake &>/dev/null
  hasCMake=$?

  which ninja &>/dev/null
  hasNinja=$?

  if [ $hasGit -ne 0 ]; then
    hasDepends=false
  fi
  if [ $hasCMake -ne 0 ]; then
    hasDepends=false
  fi
  if [ $hasNinja -ne 0 ]; then
    hasDepends=false
  fi

  if [ $hasDepends != true ]; then
    echo "Missing dependencies..."
    exit 1
  fi
}
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
  dependencies
  mkdir -p "$cmakeBuildDir"
  cd "$cmakeBuildDir" || exit 1
  $cmakePath -G Ninja ../
}

function build() {
  dependencies
  cd "$cmakeBuildDir" || exit 1
  $ninjaPath -j$cpuCores
}

function generateRelease() {
  dependencies
  mkdir -p "$cmakeBuildDir"
  cd "$cmakeBuildDir" || exit 1
  $cmakePath -DCMAKE_BUILD_TYPE=Release -G Ninja ../
}

function generateDebug() {
  dependencies
  mkdir -p "$cmakeBuildDir"
  cd "$cmakeBuildDir" || exit 1
  $cmakePath -DCMAKE_BUILD_TYPE=Debug -G Ninja ../
}

function clean() {
  rm -rf "$cmakeBuildDir"
  rm -rf "$rootDir/debug"
}

function gitAdd() {
  dependencies
  $gitPath add $1
}

function gitCommit() {
  dependencies
  $gitPath commit -am "$@"
}

function gitPush() {
  dependencies
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

function debug() {
  echo "Cleaning"
  clean
  echo "Creating directories"
  mkdir -p ./debug/sources
  echo "Generating"
  generateDebug
  echo "Building"
  build
  echo "Copying Binaries"
  cd $cmakeBuildDir || exit 1
  find ./ -maxdepth 1 -perm /a+x -type f -exec cp {} $rootDir/debug/ \;
  cd $rootDir || exit 1
  echo "Copying Sources"
  cp *.c *.h $rootDir/debug/sources
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
  if [ $1 = "debug" ]; then
    debug
    exit 0
  fi
  if [ $1 = "cab" ]; then
    cleanAndBuild
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
    echo "'depends': Check if the necessary dependencies are installed"
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
    echo "'debug': Generate debugging files"
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
    echo "Add takes multiple files"
    echo "Commit takes a message in double quotes"
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
