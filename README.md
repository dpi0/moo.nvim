# `moo.nvim`

Shows a live markdown preview of the current buffer's `.md` file using the cli tool [gh-markdown-preview](https://github.com/yusukebe/gh-markdown-preview)

## Requirements

[Neovim](https://github.com/neovim/neovim) 0.8.0+

[gh-markdown-preview](https://github.com/yusukebe/gh-markdown-preview) 1.8.0+

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'dpi0/moo.nvim',
}
```

## Usage

Call the preview function to launch a preview for the current buffer in your default browser:

```lua
require("moo").preview()
```

To list all previews for the current Neovim instance:

```lua
require("moo").list_preview()
```

To kill preview for the current buffer:

```lua
require("moo").kill_preview()
```

To kill all previews for the current Neovim instance:

```lua
require("moo").kill_all_previews()
```

## Configuration


### Keybinds

```lua
keys = {
  {
    '<leader>mkp',
    function()
      require('moo').preview()
    end,
    desc = 'Markdown preview',
    mode = 'n',
  },

  -- And more
}
```

## Example Configuration I Use

```lua
return {
  'dpi0/moo.nvim',
  keys = {
    {
      '<leader>mkp',
      function()
        require('moo').preview()
      end,
      desc = 'Markdown preview',
      mode = 'n',
    },
    {
      '<leader>mkk',
      function()
        require('moo').kill_preview()
      end,
      desc = 'Kill preview for current buffer',
      mode = 'n',
    },
    {
      '<leader>mkl',
      function()
        require('moo').list_previews()
      end,
      desc = 'List all servers',
      mode = 'n',
    },
  },
}
```
