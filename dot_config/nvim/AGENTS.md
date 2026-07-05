Neovim config for a minimal terminal IDE. 

- Prefer built-in Neovim features before adding plugins.
- Do not add plugins without user's permissions.
- Use vim.pack
- Prefer minimal config, less is better. Suggest removal.

## Validation

After changing Lua files under `dot_config/nvim/`, run:

| Task             | Command                                                                  |
| ---------------- | ------------------------------------------------------------------------ |
| Format Lua       | `stylua dot_config/nvim`                                                 |
| Check formatting | `stylua --check dot_config/nvim`                                         |
| Static analysis  | `lua-language-server --check dot_config/nvim --checklevel Warning`       |
| Syntax check     | `luac -p dot_config/nvim/init.lua dot_config/nvim/lua/gruber-darker.lua` |
| Smoke test       | `nvim --headless '+lua print("nvim-ok")' +qa`                            |
| Chezmoi dry run  | `chezmoi apply --dry-run --force`                                        |
