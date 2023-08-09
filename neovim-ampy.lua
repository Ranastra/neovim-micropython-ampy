-- config
local port = ("/dev/ttyUSB0")                                            -- port where the device is mounted, use ls /dev/tty*
local baud_rate = 115200
local project_dir = vim.fn.expand("~/Desktop/robo/robo_esp")             -- python project dir
local own_dir = vim.fn.expand("~/.config/nvim/lua/ranastra/neovim-ampy") -- dir of the ampy plugin
_G.AmpyUseTerminal = ("true")                                            -- toggle if terminal is opened for runing a python file
local debug_mode = false                                                  -- toggle to show ampy commands instead of running them
_G.AmpyAutoUpload = ("false")                                            -- toggle auto upload on save


local run_target_location = own_dir .. "/run_target.py"


local function set_target_entry(name)
	-- set python file to import target file
	local file = io.open(own_dir .. "/run_target.py", "w")
	if not file then
		print("could not open run_target.py")
		return
	end
	file:write(string.format("import %s", name))
	file:close()
end

local function run_python_file(filepath)
	-- run python file on host
	local ampy_assembled_command = string.format(
		"ampy -p %s -b %s run %s 2>&1",
		port,
		baud_rate,
		filepath
	)
	if AmpyUseTerminal == "true" then
		local term_command = string.format("term \"%s\"", ampy_assembled_command)
		if debug_mode then
			print(term_command)
			return
		end
		vim.api.nvim_command(term_command)
	else
		if debug_mode then
			print(ampy_assembled_command)
			return
		end
		local file = io.popen(ampy_assembled_command)
		if not file then
			print("Error running target", ampy_assembled_command)
			return
		end
		for line in file:lines() do
			print(line)
		end
		file:close()
	end
end

local function get_ignored_files()
	-- read the pymakr.conf ... to hold compatibility with VS**** and pymakr extension
	local config_file_path = project_dir .. "/pymakr.conf"
	local config_file = io.popen("jq '.py_ignore[]' " .. config_file_path)
	if not config_file then
		return {}
	end
	local ignored_files = {}
	for name in config_file:lines() do
		table.insert(ignored_files, name)
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

local function ampy_upload_one(name)
	-- upload file to target
	if contains(get_ignored_files(), name) then
		print("ignoring file " .. name)
		return
	end
	local ampy_assembled_command = string.format(
		"ampy -p %s -b %s put %s 2>&1",
		port,
		baud_rate,
		name
	)
	if debug_mode then
		print(ampy_assembled_command)
		return
	end
	print("uploading file " .. name)
	local output = io.popen(ampy_assembled_command)
	if not output then
		print("Error something went wrong with " .. ampy_assembled_command)
		return
	end
	for line in output:lines() do print(line) end
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
	local remove_all_command = string.format("ampy -p %s -b %s rmdir -r / 2>&1", port, baud_rate)
	if debug_mode then
		print(remove_all_command)
		return
	end
	local file = io.popen(remove_all_command)
	if not file then
		print("Error erasing files on the target")
		return
	end
	for line in file:lines() do
		print(line)
	end
	file:close()
end

_G.ampy_erase_files = function(...)
	local args = split_at(..., " ")
	if next(args) == nil then
		table.insert(args, vim.fn.expand("%:t"))
	end
	for _, filename in ipairs(args) do
		local ampy_assembled_command = string.format(
			"ampy -p %s -b %s rm %s 2>&1",
			port,
			baud_rate,
			filename
		)
		if debug_mode then
			print(ampy_assembled_command)
		else
			local output = io.popen(ampy_assembled_command)
			if not output then
				print("Error something went wrong with " .. ampy_assembled_command)
				return
			end
			for line in output:lines() do print(line) end
		end
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
		ampy_upload_one(filename)
	end
end

_G.ampy_run_target = function(filename)
	-- set entry point and run
	if filename == nil or filename == "" then
		filename = "main"
	end
	set_target_entry(filename)
	run_python_file(run_target_location)
end

_G.ampy_run_host = function(filename)
	print(filename)
	-- local filename = next(filename)
	if filename == nil or filename == "" then
		path = vim.fn.expand("%:p")
	else
		path = project_dir .. "/" .. filename
	end
	-- run local python file
	run_python_file(path)
end

_G.ampy_upload_files = function(...)
	local args = split_at(..., " ")
	if next(args) == nil then
		ampy_upload_one(vim.fn.expand("%:p"))
	else
		for _, filename in ipairs(args) do
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
vim.cmd([[command! -nargs=1 AmpyToggleTerminal lua AmpyUseTerminal=<f-args>]])
vim.cmd([[command! -nargs=1 AmpyToggleAutoUpload lua AmpyAutoUpload=<f-args>]])

-- autoupload
vim.cmd("autocmd BufWritePost *.py lua ampy_auto_upload()")
