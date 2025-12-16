-- moo.nvim - GitHub Markdown Preview Manager
local M = {}

-- Default configuration
M.config = {
	dark_mode = false,
	light_mode = false,
	disable_auto_open = false,
	disable_reload = false,
	host = "localhost",
	port = 3333,
	markdown_mode = false,
}

-- Store active preview jobs
local active_jobs = {}

-- Check if gh markdown-preview is available
local function has_gh_preview()
	local handle = io.popen("gh markdown-preview --help 2>&1")
	local result = handle:read("*a")
	handle:close()
	return not result:match("unknown command") and not result:match("command not found")
end

-- Get current buffer file path
local function get_current_file()
	return vim.api.nvim_buf_get_name(0)
end

-- Check if current buffer is markdown
local function is_markdown()
	return vim.bo.filetype == "markdown" or vim.bo.filetype == "md"
end

-- Notify user
local function notify(msg, level)
	vim.notify("[moo.nvim] " .. msg, level or vim.log.levels.INFO)
end

-- Build command arguments from config
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

-- Start preview for current buffer
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

	-- Check if preview already exists for this file
	if active_jobs[filepath] then
		notify("Preview already running for " .. vim.fn.fnamemodify(filepath, ":t"), vim.log.levels.WARN)
		return
	end

	-- Start the preview server
	local cmd = build_args(filepath)
	local job_id = vim.fn.jobstart(cmd, {
		on_exit = function(_, exit_code)
			active_jobs[filepath] = nil
			if exit_code ~= 0 and exit_code ~= 143 then
				notify("Preview server exited unexpectedly (code: " .. exit_code .. ")", vim.log.levels.ERROR)
			end
		end,
		stdout_buffered = true,
		stderr_buffered = true,
	})

	if job_id > 0 then
		active_jobs[filepath] = job_id
		notify(
			"Preview is live for " .. vim.fn.fnamemodify(filepath, ":t") .. " - check your browser!",
			vim.log.levels.INFO
		)
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
	for filepath, job_id in pairs(active_jobs) do
		table.insert(lines, "  • " .. filepath .. " (job: " .. job_id .. ")")
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

	vim.fn.jobstop(active_jobs[filepath])
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
	for filepath, job_id in pairs(active_jobs) do
		vim.fn.jobstop(job_id)
		count = count + 1
	end

	active_jobs = {}
	notify("Stopped " .. count .. " preview(s).", vim.log.levels.INFO)
end

-- Setup function for configuration
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M
