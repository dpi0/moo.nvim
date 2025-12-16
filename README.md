# `moo.nvim`

Shows a live markdown preview of the current buffer's `.md` file using the cli tool [gh-markdown-preview](https://github.com/yusukebe/gh-markdown-preview)

<img width="710.8" height="400" alt="Notification inside Neovim" src="https://github.com/user-attachments/assets/e0027fdb-c21d-4d7e-ade4-1f54124ad4c8" />

<img width="710.8" height="400" alt="Preview in Firefox" src="https://github.com/user-attachments/assets/0256d98c-e828-4eb8-989c-3aecac6ed066" />

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

To install `gh-markdown-preview` using the [GitHub gh cli](https://github.com/cli/cli#installation), [refer](https://github.com/yusukebe/gh-markdown-preview#installation)

```bash
gh extension install yusukebe/gh-markdown-preview
```

> [!WARNING]
> `gh markdown-preview` works only when online as it uses the GitHub API for preview. Use the hard fork [gfm](https://github.com/thiagokokada/gh-gfm-preview) for offline only usage.

## Usage

Call the preview function to launch a preview for the current buffer in your default browser:

```lua
:lua require("moo").preview()
```

To list all previews for the current Neovim instance:

```lua
:lua require("moo").list_previews()
```

To kill preview for the current buffer:

```lua
:lua require("moo").kill_preview()
```

To kill all previews for the current Neovim instance:

```lua
:lua require("moo").kill_all_previews()
```

## Configuration

### Options

These are implemented in reference to `gh markdown-preview --help`

```lua
opts = {
  dark_mode = false, -- Force dark mode (Default: false)
  light_mode = false, -- Force light mode (Default: false)
  disable_auto_open = false, -- Don't auto-open browser (Default: false)
  disable_reload = false, -- Disable live reloading (Default: false)
  host = 'localhost', -- Hostname this server will bind (Default: 'localhost')
  port = 3333, -- TCP port number of this server (Default: 3333)
  markdown_mode = false, --  Force "markdown" mode (Rather than the Default: "gfm")
}
```

### Keybinds

```lua
keys = {
  {
    '<leader>mkp',
    function()
      require('moo').preview()
    end,
    desc = '[M]ar[k]down [P]review',
    mode = 'n',
  },

  -- And more
}
```

## Example Configuration for lazy.nvim

```lua
return {
  'dpi0/moo.nvim',
  ft = 'markdown', -- Only load the plugin for `.md` files
  opts = {
    markdown_mode = true, -- Force "markdown" mode (Default: false)
  },
  keys = {
    {
      '<leader>mkp',
      function()
        require('moo').preview()
      end,
      desc = '[M]ar[k]down [P]review',
      mode = 'n',
    },
    {
      '<leader>mkl',
      function()
        require('moo').list_previews()
      end,
      desc = '[M]ar[k]down [L]ist Previews',
      mode = 'n',
    },
    {
      '<leader>mkk',
      function()
        require('moo').kill_preview()
      end,
      desc = '[M]ar[k]down [K]ill Current Buffer Preview',
      mode = 'n',
    },
    {
      '<leader>mkK',
      function()
        require('moo').kill_all_previews()
      end,
      desc = '[M]ar[k]down [K]ill All Previews',
      mode = 'n',
    },
  },
}
```
