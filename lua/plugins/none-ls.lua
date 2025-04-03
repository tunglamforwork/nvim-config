return {
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
      local null_ls = require("null-ls")
      local sources = {
        -- python
        null_ls.builtins.formatting.black.with({
          extra_args = { "--line-length=120", "--skip-string-normalization" },
        }),
      }
      null_ls.setup({ sources = sources })
    end,
  },
}
