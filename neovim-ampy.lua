-- config
local port = ("/dev/ttyUSB0")                                            -- port where the device is mounted, use ls /dev/tty*
local baud_rate = 115200
local project_dir = vim.fn.expand("~/Desktop/robo/robo_esp")        -- python project dir
local own_dir = vim.fn.expand("~/.config/nvim/lua/ranastra/neovim-ampy") -- dir of the ampy plugin
-- _G.AmpyUseTerminal = ("true")                                            -- toggle if terminal is opened for runing a python file
local debug_mode = false                                                 -- toggle to show ampy commands instead of running them
_G.AmpyAutoUpload = ("false")                                            -- toggle auto upload on save
local sudo_password = nil                                                -- dont set that .....
local password_mode = 2                                                  -- 1 ask for sudo password eveytime, 2 ask for password once per start of nvim, 3 specify password in this file

local run_target_location = own_dir .. "/run_target.py"

local function set_password()
	-- set local sudo_password and will be called the first run_bash_command is called
	vim.api.nvim_out_write("enter sudo password: ")
	vim.api.nvim_command("startinsert")
	sudo_password = vim.fn.input("")
	vim.api.nvim_command("stopinsert")
end

local function run_bash_command(cmd)
	-- this should handle all cringeness of permission and opening terminals
	-- write bash file
	if debug_mode then
		print(cmd)
		return
	end
	local file = io.open(own_dir .. "/bash_run.sh", "w")
	if not file then
		print("could not create bash_run file")
		return
	end
	file:write(cmd)
	file:close()
	-- run bash file
	if password_mode == 1 then
		local command = ":terminal sudo -S bash " .. own_dir .. "/bash_run.sh"
		vim.api.nvim_command(command)
	elseif password_mode == 2 then
		if not sudo_password then
			set_password()
		end
		local command = ":!echo " .. sudo_password .. " | sudo -S bash " .. own_dir .. "/bash_run.sh"
		vim.api.nvim_command(command)
	else
		if not sudo_password then
			print("no sudo password set in config, but mode specified")
			return
		end
		local command = ":!echo " .. sudo_password .. " | sudo -S bash " .. own_dir .. "/bash_run.sh"
		vim.api.nvim_command(command)
	end
end

local function set_target_entry(filename)
	-- set python file to import target file
	-- filename without .py fileextension
	local file = io.open(own_dir .. "/run_target.py", "w")
	if not file then
		print("could not open run_target.py")
		return
	end
	file:write(string.format("import %s", filename))
	file:close()
end

local function run_python_file(filepath)
	-- run python file on host
	local ampy_assembled_command = string.format(
		"ampy -p %s -b %s run %s",
		port,
		baud_rate,
		filepath
	)
	run_bash_command(ampy_assembled_command)
end

local function get_ignored_files()
	-- read the pymakr.conf ... to hold compatibility with VS**** and pymakr extension
	local jq_command = "jq -r '.py_ignore[]' " .. project_dir .. "/pymakr.conf 2>/dev/null"
	local config_file = io.popen(jq_command, "r")
	if not config_file then
		return {}
	end
	local ignored_files = {}
	for name in config_file:lines() do
		table.insert(ignored_files, project_dir .. "/" .. name)
	end
	return ignored_files
end

local function contains(table, value)
	-- helper function membership test
	for _, v in pairs(table) do
		if v == value then
			return true
		end
	end
	return false
end

local function ampy_upload_one(filepath)
	-- upload file to target
	if contains(get_ignored_files(), filepath) then
		print("ignoring file " .. filepath)
		return
	end
	local ampy_assembled_command = string.format(
		"ampy -p %s -b %s put %s",
		port,
		baud_rate,
		filepath
	)
	run_bash_command(ampy_assembled_command)
end

local function split_at(inpstring, sep)
	-- helper function for spliting strings
	local split = {}
	local current = ""
	for c in inpstring:gmatch "." do
		if c == sep then
			table.insert(split, current)
			current = ""
		else
			current = current .. c
		end
	end
	if current ~= "" then
		table.insert(split, current)
	end
	return split
end

_G.ampy_erase_all = function()
	-- remove all files from target
	local ampy_assembled_command = string.format(
		"ampy -p %s -b %s rmdir -r / 2>&1",
		port,
		baud_rate
	)
	run_bash_command(ampy_assembled_command)
end

_G.ampy_erase_files = function(...)
	-- remove given files
	local filenames = split_at(..., " ")
	if next(filenames) == nil then
		table.insert(filenames, vim.fn.expand("%:t"))
	end
	for _, filename in ipairs(filenames) do
		local ampy_assembled_command = string.format(
			"ampy -p %s -b %s rm %s 2>&1",
			port,
			baud_rate,
			filename
		)
		run_bash_command(ampy_assembled_command)
	end
end

_G.ampy_upload_all = function()
	-- upload all files in project dir to target
	local directory_contents = io.popen("ls " .. project_dir)
	if not directory_contents then
		print("project directory " .. project_dir .. " not found")
		return
	end
	for filename in directory_contents:lines() do
		ampy_upload_one(project_dir .. "/" .. filename)
	end
end

_G.ampy_run_target = function(filename)
	-- set entry point and run
	-- filename without .py fileextension
	if filename == nil or filename == "" then
		filename = "main"
	end
	set_target_entry(filename)
	run_python_file(run_target_location)
end

_G.ampy_run_host = function(filename)
	print(filename)
	-- local filename = next(filename)
	local path
	if filename == nil or filename == "" then
		path = vim.fn.expand("%:p")
	else
		path = project_dir .. "/" .. filename
	end
	-- run local python file
	run_python_file(path)
end

_G.ampy_upload_files = function(...)
	local filenames = split_at(..., " ")
	if next(filenames) == nil then
		print("in upload current")
		ampy_upload_one(vim.fn.expand("%:p"))
	else
		print("in upload list of files")
		for _, filename in ipairs(filenames) do
			ampy_upload_one(project_dir .. "/" .. filename)
		end
	end
end

_G.ampy_auto_upload = function()
	if AmpyAutoUpload == "true" then
		ampy_upload_files("")
	end
end

-- ampy commands

-- upload files given as args default is current
vim.cmd([[command! -nargs=* AmpyUpload lua ampy_upload_files("<args>")]])
-- overwrite with whole program folder
vim.cmd([[command! AmpyUploadAll lua ampy_upload_all()]])
-- erase files given as args default is current
vim.cmd([[command! -nargs=* AmpyErase lua ampy_erase_files("<args>")]])
-- erase all files on deviece
vim.cmd([[command! AmpyEraseAll lua ampy_erase_all()]])
-- run current opened file (on Host) or file in project dir
vim.cmd([[command! -nargs=* AmpyRun lua ampy_run_host("<args>")]])
-- run file (on Target) default is main.py, dont pass fileextension!!
vim.cmd([[command! -nargs=* AmpyRunTarget lua ampy_run_target("<args>")]])

-- toggle modes
-- vim.cmd([[command! -nargs=1 AmpyToggleTerminal lua AmpyUseTerminal=<f-args>]])
vim.cmd([[command! -nargs=1 AmpyToggleAutoUpload lua AmpyAutoUpload=<f-args>]])

-- autoupload
vim.cmd("autocmd BufWritePost *.py lua ampy_auto_upload()")
