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

~~- AmpyToggleTerminal true|false    : toggle if terminal is opened when python file is run with ampy~~
- AmpyToggleAutoUpload true|false  : toggle if pyton file is automatically uploaded when it is saved

# Requirements
- adafruit-ampy
- jq for reading the pymakr.conf file

# Configuration
- bash_run.sh needs to be executable ... thats where the ampy command is written to
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
- password_mode 1|2|3 : ampy needs sudo permissions in order to acces a port at /dev. there are 3 modes to enable it. 
  - 1 neovim asks for the password at every execution of one of the commands
  - 2 the password is asked only once in a session and is stored while neovim is running 
  - 3 or you can set your password in the config section of the lua file 
  ... (Ik the last two options are not nice but neovim forces me to use them and I dont really care as long as its working)
  ...... (also toggle terminal is removed as whether a terminal is opened or not depends on how the password for sudo is passed)

The code probably contains a lot of bugs, and is also not properly tested, contributions are welcome :)
