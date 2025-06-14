# sword-nvim.lua

A swapping word plugin I made for neovim

## Install

```lua
return {
  "indyleo/sword-nvim",
  lazy = false,
  config = true,
}
```

Add this snippet to your LazyVim plugin spec (ideally in its own file for better organization).

## Commands

- `:SwapNext`/ `:SwapPrev`
  Swaps the current cword with something depending on what it is in an array, backwards or forwards
  example:

  - on <-> off
  - off <-> on

- `:SwapReload`
  Reloads the active swaps

- `:SwapList`
  Show a list of active swaps gives an index/number

- `:SwapAdd {...}`
  add what you want to swap with what

- `:SwapRm`
  Remove a swap based off its index from `:SwapList`
