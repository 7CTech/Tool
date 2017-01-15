# Tool

tool.sh is a simple tool for managing C/C++ projects that use Git. It was designed after I got tired of typing out CMake commands.



## Dependencies

There are a few dependencies for this script, as they are used in some of it's functions. The script will check for dependencies at the start of most functions.

The dependencies are:

- Git
- CMake
- Ninja



## Installation

1. [Download this repository](https://github.com/7CTech/Tool/archive/master.zip)
2. Extract the zip file somewhere
3. Copy the file tool.sh into the root directory of your project
4. Give the tool executable permissions (`chmod +x tool.sh`)
5. Check if you have the necessary dependencies installed (`./tool.sh depends`)
6. (Optional) Customise the Generation and Build functions to suit your project (Eg. Change compiler, CMake options, Check for necessary project dependencies, etc.)



## Usage

### Miscellaneous

- 'depends': Check if necessary tool.sh and project dependencies are installed
- 'help': Show this message
- 'version': Output version information

### Building

- 'build': Build project using ninja (Generation is done automatically)
- 'gen': Generate CMake build files
- 'release': Build release binaries (Generation is done automatically)

### Maintenance

- 'clean': Clean CMake files, debugging files, and generated files
- 'debug': Generate debugging files

### Git

- 'add' \<files>: Track the specified files with git (Takes multiple files)
- 'commit: "message": commits tracked changed files (Takes a message in double quotes)
- 'push': Pushes pending commits

### Joint Commands

- 'cab': Clean and Build
- 'cap': Commit and Push


If you have found an issue or would like to request a new feature, please [add an issue](https://github.com/7CTech/Tool/issues/new)
