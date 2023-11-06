<h1 align=center>Oatmeal.nvim</h1>

![oatmeal](.github/banner.png)

> Terminal UI to chat with large language models (LLM) using different model backends, and direct integration with Neovim!

- [Overview](#Overview)
- [Install](#Install)
  - [lazy.nvim](#lazy-nvim)
  - [Default Configuration](#default-configuration)
- [Usage](#Usage)
- [License](#license)

## Overview

Oatmeal is a terminal UI chat application that speaks with LLMs, complete with slash commands for familiar usage. It features agnostic backends to allow switching between the powerhouse of ChatGPT, or keeping things private with Ollama. This plugin provides a direct integration with Oatmeal directly from Neovim!

See it in action (click to restart):

![oatmeal-demo](https://github.com/dustinblackman/oatmeal/assets/5246169/4fead112-5d37-497d-b270-a806fac41a17)

## Install

You must have Oatmeal installed on your system in order to use the plugin. See the main
[Oatmeal](https://github.com/dustinblackman/oatmeal) repo for installation details.

### lazy.nvim

```lua
{
    "dustinblackman/oatmeal.nvim",
    cmd = { "Oatmeal" },
    keys = {
        { "<leader>om", mode = "n", desc = "Start Oatmeal session" },
        { "<leader>om", mode = "v", desc = "Start Oatmeal session" },
    },
    config = function()
        require("oatmeal").setup({
            backend = "ollama",
            model = "codellama:latest",
        })
    end,
},
```

## Default Configuration

All configuration variables are optional and will default to what is set in the CLI defaults.

```lua
{
    backend = "",
    model = "",
    theme = "",
    theme_file = "",
    openapi_url = "",
    openapi_token = "",
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
