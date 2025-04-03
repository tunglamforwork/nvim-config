return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      {
        "s1n7ax/nvim-window-picker",
        version = "2.*",
        config = function()
          require("window-picker").setup({
            filter_rules = {
              include_current_win = false,
              autoselect_one = true,
              bo = {
                filetype = { "neo-tree", "neo-tree-popup", "notify" },
                buftype = { "terminal", "quickfix" },
              },
            },
          })
        end,
      },
    },
    config = function()
      -- Custom path handling functions
      local utils = {
        sanitize_path = function(path)
          if vim.fn.has("win32") == 1 then
            -- Convert Windows backslashes to forward slashes
            path = path:gsub("\\", "/")
          end
          return path
        end,

        safe_path_to_buf = function(path)
          if not path then
            return
          end
          path = utils.sanitize_path(path)

          -- Check if buffer already exists
          local bufnr = vim.fn.bufnr(path)
          if bufnr > 0 then
            vim.api.nvim_set_current_buf(bufnr)
            return
          end

          -- Create new buffer and set it
          local cmd = string.format("e %s", vim.fn.fnameescape(path))
          local ok, err = pcall(vim.cmd, cmd)
          if not ok then
            -- Fallback method if the first attempt fails
            bufnr = vim.fn.bufadd(path)
            vim.api.nvim_set_current_buf(bufnr)
            -- Load the buffer content
            vim.api.nvim_buf_set_option(bufnr, "buflisted", true)
          end
        end,
      }

      require("neo-tree").setup({
        sources = { "filesystem", "buffers", "git_status" },
        open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
        close_if_last_window = true,
        filesystem = {
          bind_to_cwd = false,
          follow_current_file = { enabled = true },
          use_libuv_file_watcher = true,
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_hidden = false,
            hide_by_name = {
              ".DS_Store",
              "thumbs.db",
              "node_modules",
              "__pycache__",
              ".virtual_documents",
              ".git",
              ".python-version",
              ".venv",
            },
            hide_by_pattern = {}, -- Remove patterns to avoid conflicts
            always_show = {
              ".gitignored",
              ".env",
            },
            never_show = {
              ".DS_Store",
              "thumbs.db",
            },
          },
          commands = {
            -- Add custom command to handle file opening
            open_file = function(state)
              local node = state.tree:get_node()
              if node.type == "file" then
                utils.safe_path_to_buf(node.path)
              end
            end,
          },
        },
        window = {
          width = 30,
          mappings = {
            ["l"] = "open_file", -- Use our custom command
            ["h"] = "close_node",
            ["<space>"] = "none",
            ["t"] = function(state)
              local node = state.tree:get_node()
              vim.cmd("tabnew")
              utils.safe_path_to_buf(node.path)
            end,
            ["s"] = function(state)
              local node = state.tree:get_node()
              vim.cmd("vsplit")
              utils.safe_path_to_buf(node.path)
            end,
            ["Y"] = {
              function(state)
                local node = state.tree:get_node()
                vim.fn.setreg("+", utils.sanitize_path(node:get_id()), "c")
              end,
              desc = "Copy Path to Clipboard",
            },
          },
        },
        event_handlers = {
          {
            event = "file_opened",
            handler = function(file_path)
              require("neo-tree").close_all()
            end,
          },
          {
            event = "neo_tree_buffer_enter",
            handler = function(arg)
              vim.opt.relativenumber = true
            end,
          },
        },
        default_component_configs = {
          indent = {
            with_expanders = true,
            expander_collapsed = "",
            expander_expanded = "",
            expander_highlight = "NeoTreeExpander",
          },
          diagnostics = {
            symbols = {
              hint = "",
              info = "",
              warning = "",
              error = "",
            },
            highlights = {
              hint = "DiagnosticSignHint",
              info = "DiagnosticSignInfo",
              warn = "DiagnosticSignWarn",
              error = "DiagnosticSignError",
            },
          },
          git_status = {
            symbols = {
              unstaged = "",
              staged = "S",
              unmerged = "",
              renamed = "➜",
              untracked = "U",
              deleted = "",
              ignored = "◌",
            },
          },
        },
      })

      -- Add these settings to help with special characters in paths
      vim.opt.isfname:append("@-@")
      vim.opt.isfname:append("(")
      vim.opt.isfname:append(")")

      if vim.fn.has("win32") == 1 then
        vim.opt.shellslash = true
      end
    end,
  },
}
