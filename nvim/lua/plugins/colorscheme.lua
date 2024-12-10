-- Plugins are automatically loaded after lazy.nvim startup
-- Default colorscheme that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/colorscheme.lua
-- Add any additional colorscheme here
return {
  -- rose-pine
  {
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
      require("rose-pine").setup({
        -- disable_background = true, -- Enable transparent background
      })
      vim.cmd("colorscheme rose-pine") -- Activate the theme
    end,
  },
}
