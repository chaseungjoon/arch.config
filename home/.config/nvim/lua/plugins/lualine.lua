return {
    'nvim-lualine/lualine.nvim',
    config = function()
        -- AMBER-76 statusline: flat blocks, no powerline arrows
        local c = {
            bg0 = "#1c1b19", bg1 = "#2a2723", bg2 = "#3c3833", dim = "#9a8f7a", fg = "#e8dcc0",
            amber = "#ffb000", orange = "#e8742c", red = "#d0453b", teal = "#3e9d9a", green = "#8fb339",
        }
        local function mode(color)
            return {
                a = { fg = c.bg0, bg = color, gui = "bold" },
                b = { fg = c.fg, bg = c.bg2 },
                c = { fg = c.dim, bg = c.bg1 },
            }
        end
        local amber76 = {
            normal = mode(c.amber),
            insert = mode(c.green),
            visual = mode(c.orange),
            replace = mode(c.red),
            command = mode(c.teal),
            terminal = mode(c.teal),
            inactive = {
                a = { fg = c.dim, bg = c.bg1 },
                b = { fg = c.dim, bg = c.bg1 },
                c = { fg = c.dim, bg = c.bg0 },
            },
        }
        require('lualine').setup(
            {
                options = {
                    theme = amber76,
                    component_separators = { left = '|', right = '|' },
                    section_separators = { left = '', right = '' },
                }
            }
        )
    end
}
