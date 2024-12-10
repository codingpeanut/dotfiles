# lazy.nvim

## ✨ My lazyvim config
> My config is build up by `LazyVim/starter`
```plaintext
~/.config/nvim
├── lua
│   ├── config
│   │   ├── autocmds.lua
│   │   ├── keymaps.lua
│   │   ├── lazy.lua
│   │   └── options.lua
│   └── plugins
│       ├── colorscheme.lua
│       └── editor.lua
└── init.lua
```
### 🔎 Modified Part
- rose-pine colorscheme `(colorscheme.lua)`
- disable neo-tree `(editor.lua)`

## ⚡️ Requirements
- Neovim >= **0.8.0** (needs to be built with **LuaJIT**)
- Git >= **2.19.0** (for partial clones support)
- a [Nerd Font](https://www.nerdfonts.com/) **_(optional)_**
- [luarocks](https://luarocks.org/) to install rockspecs.
  You can remove `rockspec` from `opts.pkg.sources` to disable this feature.

## 🛠️ Installation
- Clone the starter
```plaintext
git clone https://github.com/codingpeanut/lazy.nvim $env:LOCALAPPDATA\nvim
```

- Remove the .git folder, so you can add it to your own repo later
```plaintext
Remove-Item $env:LOCALAPPDATA\nvim\.git -Recurse -Force
```

- Start Neovim!
```plaintext
nvim
```
