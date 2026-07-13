return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local ts = require("nvim-treesitter")
			ts.setup({})

			local ensure = { "javascript", "typescript", "rust", "jsdoc", "bash" }
			local missing = vim.tbl_filter(function(p)
				return not vim.tbl_contains(ts.get_installed(), p)
			end, ensure)
			if #missing > 0 then
				ts.install(missing)
			end

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(ev)
					local ft, buf = ev.match, ev.buf

					-- old `disable`: skip html
					if ft == "html" then
						return
					end

					-- old `disable`: skip files > 100KB
					local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
					if ok and stats and stats.size > 100 * 1024 then
						vim.notify(
							"File larger than 100KB treesitter disabled for performance",
							vim.log.levels.WARN,
							{ title = "Treesitter" }
						)
						return
					end

					-- old `auto_install`: pull the parser on demand if available
					local lang = vim.treesitter.language.get_lang(ft) or ft
					if not vim.tbl_contains(ts.get_installed(), lang) then
						if vim.tbl_contains(ts.get_available(), lang) then
							ts.install({ lang }):await(function()
								pcall(vim.treesitter.start, buf, lang)
							end)
						end
						return
					end

					-- old `highlight = { enable = true }`
					pcall(vim.treesitter.start, buf, lang)

					-- old `additional_vim_regex_highlighting = { "markdown" }`
					if ft == "markdown" then
						vim.bo[buf].syntax = "on"
					end

					-- old `indent = { enable = true }`
					vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		after = "nvim-treesitter",
		config = function()
			require("treesitter-context").setup({
				enable = false,
				multiwindow = false,
				max_lines = 0,
				min_window_height = 0,
				line_numbers = true,
				multiline_threshold = 20,
				trim_scope = "outer",
				mode = "cursor",
				separator = nil,
				zindex = 20,
				on_attach = nil,
			})
		end,
	},
}
