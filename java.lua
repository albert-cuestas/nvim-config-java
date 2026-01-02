local function jhome(v)
  return vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v " .. v))
end

local home21 = jhome(21)
local home25 = jhome(25)
local home17 = jhome(17)
local home11 = jhome(11)

local function switch_runtime_with_callback(on_complete)
  local clients = vim.lsp.get_clients({ name = "jdtls" })
  local client
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

  local runtimes = (client.config.settings.java.configuration or {}).runtimes or {}
  if #runtimes == 0 then
    vim.notify("No runtimes configured", vim.log.levels.WARN)
    return
  end

  vim.ui.select(runtimes, {
    prompt = "Select Java Runtime:",
    format_item = function(runtime)
      local marker = runtime.default and " (current)" or ""
      return runtime.name .. " - " .. runtime.path .. marker
    end,
  }, function(selected)
    if not selected then
      return
    end

    for _, r in pairs(runtimes) do
      r.default = (r == selected)
    end

    client:notify("workspace/didChangeConfiguration", { settings = client.config.settings })
    vim.notify("Runtime changed to: " .. selected.name, vim.log.levels.INFO)

    if on_complete then
      on_complete(selected)
    end
  end)
end

vim.api.nvim_create_user_command("JdtSwitchRuntime", function()
  switch_runtime_with_callback(function(selected)
    vim.notify("Updating project configuration...", vim.log.levels.INFO)
    require("jdtls").update_projects_config()
    vim.defer_fn(function()
      vim.notify("Updating debug configuration...", vim.log.levels.INFO)
      require("jdtls.dap").setup_dap_main_class_configs({ verbose = true })
      vim.notify("Runtime " .. selected.name .. " ready for debug", vim.log.levels.INFO)
    end, 500)
  end)
end, { desc = "Switch Java runtime and update DAP config" })

return {
  {
    "mfussenegger/nvim-jdtls",
    opts = {
      settings = {
        java = {
          configuration = {
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
      { "<leader>cjr", "<cmd>JdtSwitchRuntime<cr>", desc = "Switch Java Runtime" },
    },
  },
}
