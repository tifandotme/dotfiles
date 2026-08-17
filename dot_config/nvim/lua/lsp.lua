local M = {}

function M.setup(user_group)
  vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
  })

  vim.api.nvim_create_user_command("LspClients", function()
    vim.print(vim.lsp.get_clients({ bufnr = 0 }))
  end, {})

  vim.api.nvim_create_user_command("LspFormatters", function()
    vim.print(vim.tbl_map(function(client)
      return {
        name = client.name,
        format = client:supports_method("textDocument/formatting", 0),
      }
    end, vim.lsp.get_clients({ bufnr = 0 })))
  end, {})

  vim.api.nvim_create_user_command("LspRestartBuffer", function()
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      client:stop(true)
    end
    vim.cmd.edit()
  end, {})

  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
  vim.lsp.config("*", {
    capabilities = require("mini.completion").get_lsp_capabilities(),
  })

  vim.lsp.config("oxfmt", {
    root_dir = function(bufnr, on_dir)
      local path = vim.api.nvim_buf_get_name(bufnr)
      on_dir(vim.fs.root(path, ".git") or vim.fs.dirname(path))
    end,
  })

  vim.lsp.config("superhtml", {
    cmd = { "superhtml", "lsp" },
    filetypes = { "html", "htm", "shtml", "xml" },
    root_markers = { ".git" },
  })

  vim.lsp.config("stylua", {
    cmd = { "stylua", "--lsp" },
    filetypes = { "lua", "luau" },
    root_markers = { ".stylua.toml", "stylua.toml", ".git" },
  })

  vim.lsp.config("lua_ls", {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = { library = vim.api.nvim_get_runtime_file("", true) },
      },
    },
  })

  vim.lsp.config("vtsls", {
    settings = {
      vtsls = {
        tsserver = {
          globalPlugins = {
            {
              name = "@effect/language-service",
              location = vim.fn.expand("~/.local/share/bun/install/global/node_modules"),
              enableForWorkspaceTypeScriptVersions = true,
            },
          },
        },
      },
    },
  })

  vim.lsp.config("tinymist", {
    settings = {
      formatterPrintWidth = 80,
      formatterIndentSize = 2,
    },
  })

  vim.lsp.enable({
    "bashls",
    "vtsls",
    "oxfmt",
    "oxlint",
    "superhtml",
    "gopls",
    "jsonls",
    "stylua",
    "tombi",
    "tinymist",
    "lua_ls",
    "nushell",
    "yamlls",
  })
end

return M
