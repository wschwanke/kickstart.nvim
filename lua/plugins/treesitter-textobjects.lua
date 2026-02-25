return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {},
  config = function()
    require("nvim-treesitter.configs").setup({
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = { query = "@function.outer", desc = "Around Function" },
            ["if"] = { query = "@function.inner", desc = "Inside Function" },
            ["ac"] = { query = "@class.outer", desc = "Around Class" },
            ["ic"] = { query = "@class.inner", desc = "Inside Class" },
            ["aa"] = { query = "@parameter.outer", desc = "Around Argument" },
            ["ia"] = { query = "@parameter.inner", desc = "Inside Argument" },
            ["ai"] = { query = "@conditional.outer", desc = "Around Conditional" },
            ["ii"] = { query = "@conditional.inner", desc = "Inside Conditional" },
            ["al"] = { query = "@loop.outer", desc = "Around Loop" },
            ["il"] = { query = "@loop.inner", desc = "Inside Loop" },
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ["]f"] = { query = "@function.outer", desc = "Next Function Start" },
            ["]a"] = { query = "@parameter.outer", desc = "Next Argument Start" },
          },
          goto_next_end = {
            ["]F"] = { query = "@function.outer", desc = "Next Function End" },
          },
          goto_previous_start = {
            ["[f"] = { query = "@function.outer", desc = "Prev Function Start" },
            ["[a"] = { query = "@parameter.outer", desc = "Prev Argument Start" },
          },
          goto_previous_end = {
            ["[F"] = { query = "@function.outer", desc = "Prev Function End" },
          },
        },
        swap = {
          enable = true,
          swap_next = {
            ["<leader>na"] = { query = "@parameter.inner", desc = "Swap with Next Argument" },
          },
          swap_previous = {
            ["<leader>nA"] = { query = "@parameter.inner", desc = "Swap with Previous Argument" },
          },
        },
      },
    })
  end,
}
