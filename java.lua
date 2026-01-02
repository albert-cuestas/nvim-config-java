-------------------------------------------------------------------------------
-- Java Runtime Switcher for nvim-jdtls
-- Hot-swap between different Java versions without restarting Neovim
-- Useful when working with multiple projects requiring different JDKs
-------------------------------------------------------------------------------

--- Gets the path of an installed JDK using macOS utility
--- /usr/libexec/java_home is macOS-specific and manages multiple JDKs
--- @param v number|string Java version (e.g., 17, 21, 25)
--- @return string Absolute path to JAVA_HOME for that version
local function jhome(v)
	return vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v " .. v))
end

-- Pre-load all JDK paths at startup
-- This avoids repeated system calls every time we switch runtimes
local home21 = jhome(21)
local home25 = jhome(25)
local home17 = jhome(17)
local home11 = jhome(11)

-------------------------------------------------------------------------------
-- CORE: Function to switch Java runtime in JDTLS
-------------------------------------------------------------------------------

--- Switches the Java runtime of the active JDTLS client
--- Uses vim.ui.select to show an interactive picker with available runtimes
--- @param on_complete function|nil Optional callback executed after the switch
local function switch_runtime_with_callback(on_complete)
	-- Find the active jdtls LSP client in the current buffer
	local clients = vim.lsp.get_clients({ name = "jdtls" })
	local client

	-- We iterate because get_clients returns a list, even though there's usually only one
	-- We verify it has Java config to make sure it's the correct client
	for _, c in pairs(clients) do
		if c.config.settings and c.config.settings.java then
			client = c
			break
		end
	end

	if not client then
		vim.notify("No jdtls client found", vim.log.levels.ERROR)
		return
	end

	-- Get configured runtimes with defensive programming
	-- The `or {}` prevents errors if the structure doesn't exist
	local runtimes = (client.config.settings.java.configuration or {}).runtimes or {}
	if #runtimes == 0 then
		vim.notify("No runtimes configured", vim.log.levels.WARN)
		return
	end

	-- vim.ui.select shows the native picker (or telescope/fzf if configured)
	vim.ui.select(runtimes, {
		prompt = "Select Java Runtime:",
		-- format_item customizes how each option is displayed in the picker
		format_item = function(runtime)
			local marker = runtime.default and " (current)" or ""
			return runtime.name .. " - " .. runtime.path .. marker
		end,
	}, function(selected)
		-- User cancelled the selection (ESC or similar)
		if not selected then
			return
		end

		-- Update the `default` flag on all runtimes
		-- Only the selected one gets default = true
		for _, r in pairs(runtimes) do
			r.default = (r == selected)
		end

		-- IMPORTANT: Notify the LSP about the configuration change
		-- This makes JDTLS use the new runtime without restarting
		client:notify("workspace/didChangeConfiguration", { settings = client.config.settings })
		vim.notify("Runtime changed to: " .. selected.name, vim.log.levels.INFO)

		if on_complete then
			on_complete(selected)
		end
	end)
end

-------------------------------------------------------------------------------
-- COMMAND: :JdtSwitchRuntime
-- Switches runtime AND updates project and debug configs
-------------------------------------------------------------------------------

vim.api.nvim_create_user_command("JdtSwitchRuntime", function()
	switch_runtime_with_callback(function(selected)
		-- Step 1: Update project configuration
		-- This regenerates classpaths and dependencies for the new JDK
		vim.notify("Updating project configuration...", vim.log.levels.INFO)
		require("jdtls").update_projects_config()

		-- Step 2: Update DAP (debugger) config with a small delay
		-- The defer_fn gives JDTLS time to process the project change
		-- Without this delay, DAP might pick up the old config
		vim.defer_fn(function()
			vim.notify("Updating debug configuration...", vim.log.levels.INFO)
			require("jdtls.dap").setup_dap_main_class_configs({ verbose = true })
			vim.notify("Runtime " .. selected.name .. " ready for debug", vim.log.levels.INFO)
		end, 500) -- 500ms is usually enough, adjust for very large projects
	end)
end, { desc = "Switch Java runtime and update DAP config" })

-------------------------------------------------------------------------------
-- PLUGIN CONFIG: nvim-jdtls via lazy.nvim
-------------------------------------------------------------------------------

return {
	{
		"mfussenegger/nvim-jdtls",
		opts = {
			settings = {
				java = {
					configuration = {
						-- List of available JDKs for the project
						-- JDTLS will use the one marked as `default = true`
						-- Others remain available via the :JdtSwitchRuntime command
						runtimes = {
							{ name = "JavaSE-17", path = home17, default = true },
							{ name = "JavaSE-11", path = home11 },
							{ name = "JavaSE-21", path = home21 },
							{ name = "JavaSE-25", path = home25 },
						},
					},
				},
			},
		},
		keys = {
			-- Keymap for quick runtime switching
			-- <leader>c = code actions, j = java, r = runtime
			{ "<leader>cjr", "<cmd>JdtSwitchRuntime<cr>", desc = "Switch Java Runtime" },
		},
	},
}
