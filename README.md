# kickstart.nvim

A starting point for my configuration.

![NVIM](./NVIM.png)

See [Kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) for more informations.

## Prerequisites

```bash
yay -S --needed git lazygit zoxide ripgrep fd yarn lldb nvm make unzip neovim python-pynvim wl-clipboard tree-sitter-cli

# font in archlinucn github.com/subframe7536/maple-font
yay -S ttf-maplemono-nf-cn-unhinted

# nodejs required by copilot.lua
# node version must > 16.x (18 for example)
nvm install 18
nvm use 18

# cargo/rustc required by sniprun and rustfmt
yay -S rustup
rustup toolchain install nightly # or stable
```
