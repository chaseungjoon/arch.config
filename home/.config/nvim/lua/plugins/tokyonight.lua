-- tokyonight, recoloured to AMBER-76 (the retro i3 desktop palette)
local amber76 = {
    bg0 = "#1c1b19", bg1 = "#2a2723", bg2 = "#3c3833", grey = "#4a453e", grey2 = "#5a544a",
    dim = "#9a8f7a", fg = "#e8dcc0", fg_hi = "#f4ead2",
    amber = "#ffb000", orange = "#e8742c", red = "#d0453b", red_hi = "#ef6a5a",
    mustard = "#f2c14e", yellow = "#ffcf5c", green = "#8fb339", green_hi = "#b5d36a",
    teal = "#3e9d9a", cyan = "#6fc3c0", blue = "#4f7cac", blue_hi = "#78a2d2",
    magenta = "#b5679b", magenta_hi = "#d58fc0",
}

return {
    "folke/tokyonight.nvim",
    name = "tokyonight",
    lazy = false,
    opts = {
        style = "night",
        transparent = true,
        terminal_colors = true,
        styles = {
            comments = { italic = false },
            keywords = { italic = false },
            sidebars = "transparent",
            floats = "transparent",
        },
        on_colors = function(c)
            local p = amber76
            -- base
            c.bg, c.bg_dark, c.bg_dark1, c.bg_highlight = p.bg0, p.bg0, p.bg0, p.bg1
            c.fg, c.fg_dark, c.fg_gutter = p.fg, p.dim, p.grey
            c.comment, c.dark3, c.dark5, c.terminal_black = p.grey2, p.grey, p.dim, p.grey2
            c.black = p.bg0
            -- syntax hues
            c.blue, c.blue0, c.blue1, c.blue2 = p.amber, p.bg2, p.teal, p.teal
            c.blue5, c.blue6, c.blue7 = p.mustard, p.cyan, p.bg2
            c.cyan, c.teal = p.cyan, p.teal
            c.green, c.green1, c.green2 = p.green, p.teal, p.teal
            c.magenta, c.magenta2, c.purple = p.orange, p.red_hi, p.magenta
            c.orange, c.yellow = p.orange, p.mustard
            c.red, c.red1 = p.red_hi, p.red
            -- derived ui colours (tokyonight computes these before on_colors)
            c.bg_popup, c.bg_statusline = p.bg0, p.bg1
            c.bg_visual, c.bg_search = p.bg2, p.grey
            c.border, c.border_highlight = p.grey, p.amber
            c.fg_sidebar, c.fg_float = p.dim, p.fg
            c.error, c.warning, c.info, c.hint, c.todo = p.red, p.mustard, p.teal, p.cyan, p.amber
            c.git = { add = p.green, change = p.mustard, delete = p.red, ignore = p.grey }
            c.diff = { add = "#2b3320", delete = "#3a201d", change = "#2e2a1e", text = "#4a3f22" }
            c.rainbow = { p.amber, p.orange, p.mustard, p.green, p.teal, p.magenta, p.cyan, p.red_hi }
        end,
        on_highlights = function(hl, c)
            local p = amber76
            hl.CursorLineNr = { fg = p.amber, bold = true }
            hl.LineNr = { fg = p.grey2 }
            hl.Visual = { bg = p.bg2 }
            hl.Search = { bg = p.amber, fg = p.bg0 }
            hl.IncSearch = { bg = p.orange, fg = p.bg0 }
            hl.CurSearch = { bg = p.orange, fg = p.bg0 }
            hl.MatchParen = { fg = p.amber, bold = true, underline = true }
            hl.Pmenu = { bg = p.bg1, fg = p.fg }
            hl.PmenuSel = { bg = p.amber, fg = p.bg0, bold = true }
            hl.PmenuSbar = { bg = p.bg1 }
            hl.PmenuThumb = { bg = p.amber }
            hl.FloatBorder = { fg = p.amber }
            hl.FloatTitle = { fg = p.bg0, bg = p.amber, bold = true }
            hl.WinSeparator = { fg = p.grey }
            hl.StatusLine = { fg = p.fg, bg = p.bg1 }
            hl.StatusLineNC = { fg = p.dim, bg = p.bg0 }
            hl.TelescopeBorder = { fg = p.amber }
            hl.TelescopePromptBorder = { fg = p.amber }
            hl.TelescopePromptTitle = { fg = p.bg0, bg = p.amber, bold = true }
            hl.TelescopePreviewTitle = { fg = p.bg0, bg = p.teal, bold = true }
            hl.TelescopeResultsTitle = { fg = p.bg0, bg = p.orange, bold = true }
            hl.TelescopeSelection = { fg = p.bg0, bg = p.amber }
            hl.TelescopeMatching = { fg = p.orange, bold = true }
            hl.NeoTreeDirectoryName = { fg = p.amber }
            hl.NeoTreeDirectoryIcon = { fg = p.orange }
            hl.NeoTreeRootName = { fg = p.mustard, bold = true }
            hl.NeoTreeFileName = { fg = p.fg }
            hl.NeoTreeCursorLine = { bg = p.bg1 }
            hl.CocMenuSel = { bg = p.amber, fg = p.bg0 }
            hl.CocFloating = { bg = p.bg1, fg = p.fg }
            hl.CocInlayHint = { fg = p.grey2 }
            hl.AlphaHeader = { fg = p.amber, bold = true }
            hl.AlphaLogo = { fg = p.teal, bold = true }
            hl.AlphaButtons = { fg = p.fg }
            hl.AlphaShortcut = { fg = p.orange, bold = true }
            hl.AlphaFooter = { fg = p.dim }
        end,
    },
    config = function(_, opts)
        require("tokyonight").setup(opts)
        vim.cmd.colorscheme "tokyonight"
    end
}
