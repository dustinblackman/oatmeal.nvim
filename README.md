<h1 align=center>Oatmeal.nvim</h1>

![oatmeal](.github/banner.png)

> Terminal UI to chat with large language models (LLM) using different model backends, and with a plugin for Neovim!

- [Overview](#Overview)
- [Install](#Install)
  - [lazy.nvim](#lazy-nvim)
  - [packer](#packer)
- [Default Configuration](#default-configuration)
- [Usage](#Usage)
- [License](#license)

## Overview

Oatmeal is a terminal UI chat application that speaks with LLMs, complete with slash commands for familiar usage. It features agnostic backends to allow switching between the powerhouse of ChatGPT, or keeping things private with Ollama. This plugin provides a direct integration with Oatmeal directly from Neovim!

See it in action (click to restart):

![oatmeal-demo](https://github.com/dustinblackman/oatmeal/assets/5246169/9ee5e910-4eff-4deb-8065-aeab8bfe6b00)

_Note:_ This project is still quite new, and LLM's can return unexpected answers the UI isn't prepped for. There's likely a few bugs hidden somewhere.

## Install

You must have Oatmeal installed on your system in order to use the plugin. See the main
[Oatmeal](https://github.com/dustinblackman/oatmeal) repo for installation details.

**Neovim `>=0.9.2` is required**

### lazy.nvim

```lua
{
    "dustinblackman/oatmeal.nvim",
    cmd = { "Oatmeal" },
    keys = {
        { "<leader>om", mode = "n", desc = "Start Oatmeal session" },
    },
    opts = {
        backend = "ollama",
        model = "codellama:latest",
    },
},
```

### packer

```lua
use {
    "dustinblackman/oatmeal.nvim",
    config = function()
        require("oatmeal").setup({
            backend = "ollama",
            model = "codellama:latest",
        })
    end
}
```

## Default Configuration

All configuration variables are optional and will default to what is set in the [CLI defaults](https://github.com/dustinblackman/oatmeal#usage).

```lua
{
    backend = "",
    model = "",
    theme = "",
    theme_file = "",
    ollama_url = "",
    openai_url = "",
    openai_token = "",
    close_terminal_on_quit = true
}
```

## Usage

To start up a chat session, set your cursor where you'd like new code submissions to be appended, or highlight code
you'd like to discuss with your model. After either run the `:Oatmeal` command or hit the `<leader>om` hotkey to start!

Once in a session, run `/help` to see further commands, or checkout the main
[Oatmeal](https://github.com/dustinblackman/oatmeal) repo for details.

## License

[MIT](./LICENSE)
