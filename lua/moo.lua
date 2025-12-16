local M = {}

M.config = {
	dark_mode = false,
	light_mode = false,
	disable_auto_open = false,
	disable_reload = false,
	host = "localhost",
	port = 3333,
	markdown_mode = false,
}

local active_jobs = {}

local function has_gh_preview()
	local handle = io.popen("gh markdown-preview --help 2>&1")
	local result = handle:read("*a")
	handle:close()
	return not result:match("unknown command") and not result:match("command not found")
end

local function get_current_file()
	return vim.api.nvim_buf_get_name(0)
end

local function is_markdown()
	return vim.bo.filetype == "markdown" or vim.bo.filetype == "md"
end

local function notify(msg, level)
	vim.notify("[moo.nvim] " .. msg, level or vim.log.levels.INFO)
end

local function parse_port_from_output(output)
	-- Look for "Accepting connections at http://localhost:PORT/"
	local port = output:match("Accepting connections at http://[^:]+:(%d+)")
	return port and tonumber(port) or nil
end

local function build_args(filepath)
	local args = { "gh", "markdown-preview" }

	if M.config.dark_mode then
		table.insert(args, "--dark-mode")
	end

	if M.config.light_mode then
		table.insert(args, "--light-mode")
	end

	if M.config.disable_auto_open then
		table.insert(args, "--disable-auto-open")
	end

	if M.config.disable_reload then
		table.insert(args, "--disable-reload")
	end

	if M.config.host ~= "localhost" then
		table.insert(args, "--host")
		table.insert(args, M.config.host)
	end

	if M.config.port ~= 3333 then
		table.insert(args, "--port")
		table.insert(args, tostring(M.config.port))
	end

	if M.config.markdown_mode then
		table.insert(args, "--markdown-mode")
	end

	table.insert(args, filepath)
	return args
end

function M.preview()
	if not has_gh_preview() then
		notify(
			"gh markdown-preview not available. Please install: gh extension install yusukebe/gh-markdown-preview",
			vim.log.levels.ERROR
		)
		return
	end

	if not is_markdown() then
		notify("Current buffer is not a markdown file.", vim.log.levels.WARN)
		return
	end

	local filepath = get_current_file()
	if filepath == "" then
		notify("Current buffer has no file path.", vim.log.levels.WARN)
		return
	end

	if active_jobs[filepath] then
		local job_info = active_jobs[filepath]
		if job_info.port then
			local host = M.config.host
			notify(
				"Preview already running at http://"
					.. host
					.. ":"
					.. job_info.port
					.. " for "
					.. vim.fn.fnamemodify(filepath, ":t"),
				vim.log.levels.WARN
			)
		else
			notify("Preview already starting for " .. vim.fn.fnamemodify(filepath, ":t"), vim.log.levels.WARN)
		end
		return
	end

	-- Start the preview server
	local cmd = build_args(filepath)

	local job_id = vim.fn.jobstart(cmd, {
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						-- Try to parse port from output
						local port = parse_port_from_output(line)
						if port and active_jobs[filepath] then
							active_jobs[filepath].port = port
							local host = M.config.host
							notify(
								"Preview live at http://"
									.. host
									.. ":"
									.. port
									.. " for "
									.. vim.fn.fnamemodify(filepath, ":t"),
								vim.log.levels.INFO
							)
						end
					end
				end
			end
		end,
		on_stderr = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						-- Port info might also be in stderr
						local port = parse_port_from_output(line)
						if port and active_jobs[filepath] then
							active_jobs[filepath].port = port
							local host = M.config.host
							notify(
								"Preview live at http://"
									.. host
									.. ":"
									.. port
									.. " for "
									.. vim.fn.fnamemodify(filepath, ":t"),
								vim.log.levels.INFO
							)
						end
					end
				end
			end
		end,
		on_exit = function(_, exit_code)
			active_jobs[filepath] = nil
			if exit_code ~= 0 and exit_code ~= 143 then
				notify("Preview server exited unexpectedly (code: " .. exit_code .. ")", vim.log.levels.ERROR)
			end
		end,
	})

	if job_id > 0 then
		active_jobs[filepath] = {
			job_id = job_id,
			port = nil, -- Will be populated when we parse stdout
		}
		notify("Starting preview for " .. vim.fn.fnamemodify(filepath, ":t") .. "...", vim.log.levels.INFO)
	else
		notify("Failed to start preview server.", vim.log.levels.ERROR)
	end
end

-- List all active previews
function M.list_previews()
	if vim.tbl_isempty(active_jobs) then
		notify("No active previews running.", vim.log.levels.INFO)
		return
	end

	local lines = { "Active Previews:" }
	local host = M.config.host
	for filepath, job_info in pairs(active_jobs) do
		if job_info.port then
			local url = "http://" .. host .. ":" .. job_info.port
			table.insert(lines, "  • " .. filepath .. " → " .. url)
		else
			table.insert(lines, "  • " .. filepath .. " → (starting...)")
		end
	end

	notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

-- Kill preview for current buffer
function M.kill_preview()
	local filepath = get_current_file()

	if not active_jobs[filepath] then
		notify("No active preview for current buffer.", vim.log.levels.WARN)
		return
	end

	vim.fn.jobstop(active_jobs[filepath].job_id)
	active_jobs[filepath] = nil
	notify("Preview stopped for " .. vim.fn.fnamemodify(filepath, ":t"), vim.log.levels.INFO)
end

-- Kill all active previews
function M.kill_all_previews()
	if vim.tbl_isempty(active_jobs) then
		notify("No active previews to kill.", vim.log.levels.INFO)
		return
	end

	local count = 0
	for _, job_info in pairs(active_jobs) do
		vim.fn.jobstop(job_info.job_id)
		count = count + 1
	end

	active_jobs = {}
	notify("Stopped " .. count .. " preview(s).", vim.log.levels.INFO)
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M
