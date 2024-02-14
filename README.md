# open-codeium.nvim

This project serves as an alternative to the official Codeium Neovim/Vim plugin, but using the [Open-Codeium-Engine](https://github.com/BlazeMCworld/Open-Codeium-Engine) instead.

## Features
- Ai Code Completion using codebase context
- Ai Chat

## Screenshots
![Code Completion](https://i.imgur.com/5LV10OH.png)
![Chat](https://i.imgur.com/MzXImUR.png)

## Installation

First follow the setup instructions in the engine repository.
Second, add `BlazeMCworld/open-codeium.nvim` to your plugins, and `MunifTanjim/nui.nvim` to its dependencies.

Once done, configure the keybinds. Here is an example:
```lua
local codeium = require("codeium")
vim.keymap.set("i", "<Tab>", function()
    if codeium.completions.is_shown() then
        codeium.completions.accept()
    else
        vim.fn.feedkeys("    ", "i")
    end
end)
vim.keymap.set("i", "<M-Right>", codeium.completions.next)
vim.keymap.set("i", "<M-Left>", codeium.completions.prev)
```
Valid methods are:
- `codeium.completions.is_shown()` If a completion is shown at the moment.
- `codeium.completions.accept()` Accept the current completion.
- `codeium.completions.next()` Show the next completion.
- `codeium.completions.prev()` Show the previous completion.
- `codeium.completions.dispose()` Reject the suggestions.

## Usage

Firstly, you will need to login, for that use `:CodeiumLogin`. Once that is done you can use your specified keybindings for the completions.
For getting better completions, you will most likely want to use `CodeiumIndexAdd` with a file or directory, to add it to the index.
The indexing happens locally, and may take a bit. When specifying a directory, all files will be added recursively. Files already indexed will be skipped, unless they were changed since then.
For opening the chat, just use `:CodeiumChat`, the chat history will be kept, as long as neovim is open, or until you type `/clear` (or its alias `/new`) into the chat box.
