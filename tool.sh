#!/bin/bash

##################################################
#                    Variables                   #
##################################################

RESET="\x1B[0m"

#BLACK="\x1B[30m"
#RED="\x1B[31m"
#GREEN="\x1B[32m"
#YELLLOW="\x1B[33m"
#BLUE="\x1B[34m"
#MAGENTA="\x1B[35m"
#CYAN="\x1B[36m"
#WHITE="\x1B[37m"

#BOLDBLACK="\033[1m\033[30m"
BOLDRED="\033[1m\033[31m"
#BOLDGREEN="\033[1m\033[32m"
BOLDYELLOW="\033[1m\033[33m"
#BOLDBLUE="\033[1m\033[34m"
#BOLDMAGENTA="\033[1m\033[35m"
#BOLDCYAN="\033[1m\033[36m"
BOLDWHITE="\033[1m\033[37m"

. /etc/os-release

version="v0.0.7"
hasDepends=true
projectDepends=0
gitPath=$(which git 2>&1)
cmakePath=$(which cmake 2>&1)
ninjaPath=$(which ninja 2>&1)
distro=$ID
cmakeBuildDir=$(pwd)"/build-cmake-$distro"
cpuCores=$(grep -c ^processor /proc/cpuinfo)
rootDir=$(pwd)
fileName=`basename "$0"`


##################################################
#                    Functions                   #
##################################################
function relDepends() {
  which cmake &>/dev/null
  hasCMake=$?

  which ninja &>/dev/null
  hasNinja=$?

  if [ $hasCMake -ne 0 ]; then
    hasDepends=false
  fi
  if [ $hasNinja -ne 0 ]; then
    hasDepends=false
  fi

  if [ $hasDepends != true ]; then
    echo -e "${BOLDRED}error:${RESET} missing dependencies, please run ${BOLDWHITE}'./$fileName depends'${RESET} to see which dependencies you are missing"
    exit 1
  fi
}
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
    echo -e "${BOLDRED}error:${RESET} missing dependencies, please run ${BOLDWHITE}'./$fileName depends'${RESET} to show which dependencies you are missing"
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
    echo -e "${BOLDRED}error:${RESET} missing Git"
    hasDepends=false
  else
    echo -e "Path to Git: ${BOLDWHITE}$gitPath${RESET}"
  fi
  if [ $hasCMake -ne 0 ]; then
    echo -e "${BOLDRED}error:${RESET} missing CMake"
    hasDepends=false
  else
    echo -e "Path to CMake: ${BOLDWHITE}$cmakePath${RESET}"
  fi
  if [ $hasNinja -ne 0 ]; then
    echo -e "${BOLDRED}error:${RESET} missing Ninja"
    hasDepends=false
  else
    echo -e "Path to Ninja: ${BOLDWHITE}$ninjaPath${RESET}"
  fi
}
function projectDepends() {
  true
  #Insert checks like the above for your project here
  #Python Example:
  #
  #pythonPath=$(which python 2>&1)
  #hasPython=$?
  #
  #if [ $hasPython -ne 0 ]; then
  #  echo -e "${BOLDYELLOW}warning:${RESET} missing ${BOLDWHITE}Python${RESET}, this should be non-fatal"
  #  projectDepends=1 #1 = error, 2 = warning
  #else
  #  echo -e "Path to Python: ${BOLDWHITE}$pythonPath${RESET}"
  #fi
}
function generate() {
  dependencies
  mkdir -p "$cmakeBuildDir"
  cd "$cmakeBuildDir" || exit 1
  $cmakePath -DCMAKE_BUILD_TYPE=Debug -G Ninja ../ #Insert your options
}

function build() {
  dependencies
  cd "$cmakeBuildDir" || exit 1
  $ninjaPath -j$cpuCores
}

function release() {
    clean
    relDepends
    projectDepends
    mkdir -p "$cmakeBuildDir"
    cd $"cmakeBuildDir" || exit 1
    $cmakePath -DCMAKE_BUILD_TYPE=Release -G Ninja ../ #Insert your options
    $ninjaPath -j$cpuCores
}

function generateDebug() {
  dependencies
  mkdir -p "$cmakeBuildDir"
  cd "$cmakeBuildDir" || exit 1
  $cmakePath -DCMAKE_BUILD_TYPE=Debug -G Ninja ../ #Insert your options
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
  echo "Cleaning"
  clean
  echo "Generating"
  generate
  echo "Building"
  build
  exit 0
}

function gitCommitAndPush() {
  echo "Committing with message: \"$*\""
  gitCommit "$@"
  echo "Pushing"
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
  cp *.c *.h *.cpp *.cxx *.hpp ./debug/sources
}


##################################################
#                    Arguments                   #
##################################################
if [ $# -le 0 ]; then
  echo -e "${BOLDRED}error:${RESET} no arguments, use ${BOLDWHITE}'help'${RESET} to list available arguments"
  exit 1
fi

if [ $# -eq 1 ]; then
  if [ $1 = "gen" ] || [ $1 = "generate" ]; then
    echo -e "Generating"
    generate
    exit 0
  fi
  if [ $1 = "build" ]; then
    echo -e "Generating"
    generate
    echo -e "Building"
    build
    exit 0
  fi
  if [ $1 = "buildRelease" ]; then
    echo "Building Release"
    release
    exit 0
  fi
  if [ $1 = "clean" ]; then
    echo -e "Cleaning"
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
  if [ $1 = "depends" ] || [ $1 = "dependencies" ]; then
    echo -e "Checking ${BOLDWHITE}tool.sh${RESET} dependencies"
    dependCheck
    if [ $hasDepends = true ]; then
      echo -e "All ${BOLDWHITE}tool.sh${RESET} dependencies installed \n"
    fi
    echo "Checking project dependencies"
    projectDepends
    if [ $projectDepends = 0 ]; then
      echo -e "All project dependencies installed"
    elif [ $projectDepends = 2 ]; then
      echo -e "${BOLDYELLOW}warning:${RESET} missing some non-essential project dependencies, this should be non-fatal"
    elif [ $projectDepends = 1 ]; then
      echo -e "${BOLDRED}error:${RESET} missing some project dependencies. see above about which"
      exit 1
    fi
    if [ $hasDepends = false ]; then
      echo ""
      echo -e "Missing some ${BOLDWHITE}tool.sh${RESET} dependencies. Please see above about which"
      exit 1
    fi
    exit 0
  fi
  if [ $1 = "push" ]; then
    echo -e "Pushing"
    gitPush
    exit 0
  fi
  if [ $1 = "help" ]; then
    echo -e "${BOLDWHITE}Usage:${RESET}"
    echo
    echo "Miscellaneous:"
    echo -e "${BOLDWHITE}'depends'${RESET}: Check if necessary tool.sh and project dependencies are installed"
    echo -e "${BOLDWHITE}'help'${RESET}: Show this message"
    echo -e "${BOLDWHITE}'version'${RESET}: Output version information"
    echo
    echo "Building:"
    echo -e "${BOLDWHITE}'build'${RESET}: Build project using ninja (Generation is done automatically)"
    echo -e "${BOLDWHITE}'gen'${RESET}: Generate CMake build files"
    echo -e "${BOLDWHITE}'release'${RESET}: Build release binaries (Generation is done automatically)"
    echo ""
    echo "Maintenance:"
    echo -e "${BOLDWHITE}'clean'${RESET}: Clean CMake files, debugging files, and generated files"
    echo -e "${BOLDWHITE}'debug'${RESET}: Generate debugging files"
    echo ""
    echo "Git:"
    echo -e "${BOLDWHITE}'add'${RESET} <files>: Track the specified files with git (Takes multiple files)"
    echo -e "${BOLDWHITE}'commit'${RESET} \"message\": commits tracked changed files (Takes a message in double quotes)"
    echo -e "${BOLDWHITE}'push'${RESET}: Pushes pending commits"
    echo ""
    echo "Joint Commands:"
    echo -e "${BOLDWHITE}'cab'${RESET}: Clean and build"
    echo -e "${BOLDWHITE}'cap'${RESET}: Commit and push"
    exit 0
  fi
  if [ $1 = "version" ]; then
    echo -e "${BOLDWHITE}tool.sh${RESET} version ${BOLDWHITE}$version${RESET}"
    echo -e "Latest local modification: ${BOLDWHITE}$(stat -c %y "$rootDir/$fileName")${RESET}"
    echo -e "Latest git version: ${BOLDWHITE}$(git ls-remote --tags https://github.com/7CTech/Tool.git | tail -n 1 | sed 's/^.\{51\}//')$RESET"
    echo -e "Latest git commit: ${BOLDWHITE}$(git ls-remote https://github.com/7CTech/Tool | sed -n 1p | sed 's/.\{5\}$//')${RESET}"
    exit 0
  fi
  echo -e "${BOLDRED}error:${RESET} unknown argument ${BOLDWHITE}$1${RESET}, use ${BOLDWHITE}'help'${RESET} to list available arguments"
  exit 1
fi

if [ $# -eq 2 ]; then
  if [ $1 = "commit" ]; then
    echo -e "Committing with message: \"${*:2}\""
    gitCommit "${@:2}"
    exit 0
  fi
  if [ $1 = "cap" ]; then
    gitCommitAndPush "${@:2}"
    exit 0
  fi
  if [ $1 != "add" ]; then
    echo -e "${BOLDRED}error:${RESET} unknown arguments ${BOLDWHITE}$1${RESET}, ${BOLDWHITE}$2${RESET}, use ${BOLDWHITE}'help'${BOLDWHITE} to list available arguments"
    exit 1
  fi
fi

if [ $# -ge 2 ]; then
  if [ $1 = "add" ]; then
    for (( i=2; i<=$#; i++ )); do
      echo -e "Adding ${BOLDWHITE}${!i}${RESET}"
      gitAdd ${!i}
    done
    exit 0
  fi
  echo -e "${BOLDRED}error:${RESET} unknown arguments, use ${BOLDWHITE}'help'${RESET} to list available arguments"
  exit 1
fi
