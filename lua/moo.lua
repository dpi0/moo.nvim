-- moo.nvim - GitHub Markdown Preview Manager
local M = {}

-- Store active preview jobs
local active_jobs = {}

-- Check if gh-markdown-preview is in PATH
local function has_gh_preview()
	return vim.fn.executable("gh-markdown-preview") == 1
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

-- Start preview for current buffer
function M.preview()
	if not has_gh_preview() then
		notify("gh-markdown-preview not found in PATH. Please install it first.", vim.log.levels.ERROR)
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
	local job_id = vim.fn.jobstart({ "gh-markdown-preview", filepath }, {
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

return M
