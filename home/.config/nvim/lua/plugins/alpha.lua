return {
    "goolord/alpha-nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },

    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")

        -- Header: Arch logo (teal) + NVIM (amber), side by side
        local logo = {
            [[                  ]],
            [[        /\        ]],
            [[       /  \       ]],
            [[      /\   \      ]],
            [[     /      \     ]],
            [[    /   ,,   \    ]],
            [[   /   |  |  -\   ]],
            [[  /_-''    ''-_\  ]],
        }
        local nvim = {
            [[                                              ]],
            [[                                              ]],
            [[ ██      ██  ██      ██  ██████  ██      ██ ]],
            [[ ████    ██  ██      ██    ██    ████  ████ ]],
            [[ ██  ██  ██  ██      ██    ██    ██  ██  ██ ]],
            [[ ██    ████    ██  ██      ██    ██      ██ ]],
            [[ ██      ██      ██      ██████  ██      ██ ]],
            [[                                              ]],
        }
        local header, header_hl = { "", "" }, { { { "AlphaHeader", 0, -1 } }, { { "AlphaHeader", 0, -1 } } }
        for i = 1, #logo do
            local left = logo[i] .. "  "
            header[#header + 1] = left .. nvim[i]
            header_hl[#header_hl + 1] = { { "AlphaLogo", 0, #left }, { "AlphaHeader", #left, -1 } }
        end
        dashboard.section.header.val = header
        dashboard.section.header.opts.hl = header_hl

        -- Buttons (plain text: no icon glyphs that can render as "?")
        local function button(key, label, cmd)
            local b = dashboard.button(key, ">  " .. label, cmd)
            b.opts.hl = "AlphaButtons"
            b.opts.hl_shortcut = "AlphaShortcut"
            return b
        end
        dashboard.section.buttons.val = {
            button("f", "FIND FILE", ":Telescope find_files <CR>"),
            button("e", "NEW FILE", ":ene <BAR> startinsert <CR>"),
            button("r", "RECENT FILES", ":Telescope oldfiles <CR>"),
            button("t", "FIND TEXT", ":Telescope live_grep <CR>"),
            button("c", "CONFIGURATION", ":cd ~/.config/nvim | Neotree toggle<CR>"),
            button("q", "QUIT", ":qa<CR>"),
        }

        -- Footer: user@host, hardware/OS, time
        local function trim(s)
            return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
        end

        local function read_file(path)
            local f = io.open(path, "r")
            if not f then return nil end
            local data = f:read("*a")
            f:close()
            return data
        end

        local function get_current_time()
            return os.date("%Y-%m-%d %H:%M")
        end

        local function get_user_host()
            return (os.getenv("USER") or "user") .. "@" .. vim.fn.hostname()
        end

        local function get_system_info()
            local uname = vim.uv.os_uname()
            local arch = uname.machine
            if vim.fn.has("mac") == 1 then
                local cpu = trim(vim.fn.system("sysctl -n machdep.cpu.brand_string"))
                local osver = trim(vim.fn.system("sw_vers -productVersion"))
                return string.format("%s | %s | macOS %s", cpu, arch, osver)
            end
            local cpu = (read_file("/proc/cpuinfo") or ""):match("model name%s*:%s*([^\n]+)") or "unknown cpu"
            cpu = trim(cpu:gsub("%(R%)", ""):gsub("%(TM%)", ""):gsub("CPU%s*", ""):gsub("%s+", " "))
            local os_name = (read_file("/etc/os-release") or ""):match('PRETTY_NAME="([^"]+)"') or uname.sysname
            return string.format("%s | %s | %s %s", cpu, arch, os_name, uname.release)
        end

        -- centre every footer line on its own (alpha centres the block as a whole)
        local flines = { get_user_host(), get_system_info(), get_current_time() }
        local widest = 0
        for _, l in ipairs(flines) do widest = math.max(widest, vim.fn.strdisplaywidth(l)) end
        for i, l in ipairs(flines) do
            flines[i] = string.rep(" ", math.floor((widest - vim.fn.strdisplaywidth(l)) / 2)) .. l
        end
        dashboard.section.footer.val = flines
        dashboard.section.footer.opts.hl = "AlphaFooter"

        alpha.setup(dashboard.opts)
    end,
}
