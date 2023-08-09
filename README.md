# neovim-micropython-ampy

This repo aims to make the functionality of the adafruit-ampy cli tool avaiable for convenient use in neovim. 
It provides commands to upload/run/erase files from a project directory to a micropython device, as well as an auto upload saved files option.

# Commands
- AmpyUpload <args>    : uploads files in the project directory to the micropython device, if no argument is given the current opened file is uploaded
- AmpyUploadAll        : erases all files on the micropython device and uploads all files in the project dirercory
- AmpyErase <args>     : erase files on the device given the name, default value is name of the current opened file
- AmpyEraseAll         : erase all files on the micropython device
- AmpyRun <arg>        : run file in the project directory (located on the Host), default is current opened file (could be outside of the project diirecotry)
- AmpyRunTarget <arg>  : run file that is located on the Target device (pass without file extension), default is main

- AmpyToggleTerminal true|false    : toggle if terminal is opened when python file is run with ampy
- AmpyToggleAutoUpload true|false  : toggle if pyton file is automatically uploaded when it is saved

# Configuration
- port
- baud rate
- project_dir (directory where all micropython files are kept)
- own_dir (directory of the lua code)
- a pymakr.conf file in the project directory to track files that should not be uploaded to the micropython device, files starting with . are always ignored.
The pymakr.conf should look similar to this:
`{
    "name": "esp32",
    "py_ignore": [
        "pymakr.conf",
        "some_random_text.txt"
    ]
}`
The reason for this formatting is to keep compatibility with the pymakr plugin in VSCode.

The code probably contains a lot of bugs, and is also not properly tested, contributions are welcome :)
