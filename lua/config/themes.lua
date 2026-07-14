return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    cond = function()
      return vim.startswith(TeamoXtremo.theme, "catppuccin")
    end,
    opts = {
      flavour = "mocha",
      integrations = {
        blink_cmp = true,
        treesitter = true,
        telescope = true,
        which_key = true,
        gitsigns = true,
        fidget = true,
      },
    },
  },
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    cond = function()
      return TeamoXtremo.theme == "cyberdream"
    end,
  },
  {
    "oldjobobo/retro-82.nvim",
    lazy = false,
    priority = 1000,
    cond = function()
      return TeamoXtremo.theme == "retro82"
    end,
    main = "retro82",
    opts = {
      transparent = false,
      terminal_colors = true,
    },
  },
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    cond = function()
      return TeamoXtremo.theme == "gruvbox-material"
    end,
    init = function()
      vim.g.gruvbox_material_background = "hard"
      vim.g.gruvbox_material_foreground = "material"
    end,
  },
  {
    "nyoom-engineering/oxocarbon.nvim",
    lazy = false,
    priority = 1000,
    cond = function()
      return TeamoXtremo.theme == "oxocarbon"
    end,
  },
  {
    "neanias/everforest-nvim",
    lazy = false,
    priority = 1000,
    cond = function()
      return TeamoXtremo.theme == "everforest"
    end,
    config = function()
      require("everforest").setup({
        -- Background hardness: "soft" | "medium" | "hard"
        background = "medium",
        -- Transparency: 0 = opaque, 1 = transparent, 2 = more UI elements transparent
        transparent_background_level = 0,
        -- Italic keywords and more
        italics = true,
        -- Comments are italic by default; set true to make them NOT italic
        disable_italic_comments = false,
        -- Sign column background: "none" | "grey"
        sign_column_background = "grey",
        -- Contrast of line numbers, indent lines, etc.: "low" | "high"
        ui_contrast = "low",
        -- Dim inactive windows (Neovim only)
        dim_inactive_windows = false,
        -- Also highlight the background of diagnostic error/warn/info/hint text
        diagnostic_text_highlight = true,
        -- Diagnostic virtual text colour: "grey" | "coloured"
        diagnostic_virtual_text = "coloured",
        -- Highlight diagnostic error/warn/info/hint lines
        diagnostic_line_highlight = true,
        -- Colour the foreground of spelling errors (vs. just coloured undercurls)
        spell_foreground = false,
        -- Show the EndOfBuffer (~) highlight
        show_eob = true,
        -- Floating window style: "bright" (lighter than Normal) | "dim" (darker)
        float_style = "bright",
        on_highlights = function(hl, palette)
          hl.CurrentWord = { bg = palette.bg3 }
        end,
      })
    end,
  },
}
