return
{
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"saadparwaiz1/cmp_luasnip",
		{
			"L3MON4D3/LuaSnip",
			dependencies = { "benfowler/telescope-luasnip.nvim", "rafamadriz/friendly-snippets" },
			-- follow latest release
			version = "v2.*", -- replace <CurrentMajor> by the latest released major (first number of latest release)
			-- install jsregexp (optional!)
			build = "make install_jsregexp",
			config = function()
				require "plugins.cmp.luasnip"
			end
		},
		{
			"tzachar/cmp-tabnine",
			build = "./install.sh"
		},
		{
			"zbirenbaum/copilot-cmp",
			event = { "InsertEnter", "LspAttach" },
		    fix_pairs = true,
		    config = function ()
			require "copilot_cmp".setup {}
		    end
		},
		"windwp/nvim-autopairs",
		"onsails/lspkind-nvim"
	},
	config = function()
		local cmp = require "cmp"
		local luasnip = require "luasnip"
		local lspkind = require "lspkind"
		
		local has_words_before = function()
		    unpack = unpack or table.unpack
		    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
		    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
		end
		
		local check_back_space = function()
		    local col = vim.fn.col "." - 1
		    return col == 0 or vim.fn.getline ".":sub(col, col):match "%s" ~= nil
		end
		
		cmp.setup 
		{
			enabled = {
				function()
					-- disable completion in comments
					local context = require "cmp.config.context"
					-- keep command mode completion enabled when cursor is in a comment
					if vim.api.nvim_get_mode().mode == 'c' then
								return true
					else
					    return not context.in_treesitter_capture "comment" and not context.in_syntax_group "Comment"
					end
				end    
			},
			snippet = { 
			    expand = function(args) 
					-- check if we created a snippet for this lsp-snippet.
					if lspsnips[args.body] then
					    -- use `snip_expand` to expand the snippet at the cursor position.
					    luasnip.snip_expand(lspsnips[args.body])
					else
					    luasnip.lsp_expand(args.body) 
					end
			    end 
			},
			mapping = {
			    ["<C-k>"] = cmp.mapping.select_prev_item(),
			    ["<C-j>"] = cmp.mapping.select_next_item(),
			    ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
			    ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
			    ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
			    ["<C-y>"] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
			    ["<C-e>"] = cmp.mapping { i = cmp.mapping.abort(), c = cmp.mapping.close(), },
			    ["<CR>"] = cmp.mapping.confirm (function(fallback)
					if cmp.visible() then
						if luasnip.expandable() then
							luasnip.expand()
						else
							cmp.confirm({ select = true })
						end
					else
						fallback()
					end
			    end),
			    ["<Tab>"] = vim.schedule_wrap(function(fallback)
					if cmp.visible() and has_words_before() then
					    cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
					elseif luasnip.expandable() then
					    luasnip.expand()
					elseif luasnip.expand_or_locally_jumpable() then
					    luasnip.expand_or_jump()
					elseif check_back_space() then
					    fallback()
					else
					    fallback()
					end
			    end, { "i", "s", }),
			    ["<S-Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
					    cmp.select_prev_item()
					elseif luasnip.locally_jumpable(-1) then
					    luasnip.jump(-1)
					else
					    fallback()
					end
			    end, { "i", "s", }),
			},
			formatting = {
				-- Youtube: How to set up nice formatting for your sources.
				format = function(entry, vim_item)
					-- if you have lspkind installed, you can use it like
					-- in the following line:
					vim_item.kind = lspkind.symbolic(vim_item.kind, {mode = "symbol"})
					vim_item.menu = {
						buffer = "[Buffer]",
						nvim_lsp = "[LSP]",
						copilot = "[Copilot]",
						luasnip = "[LuaSnip]",
						cmp_tabnine = "[TN]",
						path = "[Path]"
					}[entry.source.name]
					if entry.source.name == "cmp_tabnine" then
						local detail = (entry.completion_item.labelDetails or {}).detail
						vim_item.kind = ""
						if detail and detail:find(".*%%.*") then
							vim_item.kind = vim_item.kind .. " " .. detail
						end
	
						if (entry.completion_item.data or {}).multiline then
							vim_item.kind = vim_item.kind .. " " .. "[ML]"
						end
					end
					local maxwidth = 80
					vim_item.abbr = string.sub(vim_item.abbr, 1, maxwidth)
					return vim_item
				end
			},
			sources = {
				{ name = "luasnip",                 max_item_count = 5,  group_index = 1 },
				{ name = "copilot",                 max_item_count = 10,  group_index = 2 },
				{ name = "cmp_tabnine",             max_item_count = 5,  group_index = 1 },
				{ name = "nvim_lsp",                max_item_count = 20, group_index = 1 },
				{ name = "buffer",                  keyword_length = 2,  max_item_count = 5, group_index = 2 },
				{ name = "path",                    group_index = 2 }
			}
		}
	
		-- TabNine
		require "cmp_tabnine.config":setup({ max_lines = 1000, max_num_results = 20, sort = true })
		local cmp_autopairs = require "nvim-autopairs.completion.cmp"
		cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done({ map_char = { tex = "" } }))
	end
}
