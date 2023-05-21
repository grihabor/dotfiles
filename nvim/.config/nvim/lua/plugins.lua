
return require('packer').startup(function(use)	
  use 'wbthomason/packer.nvim'

-- file explorer
-- use {
--   'nvim-tree/nvim-tree.lua',
--   requires = {
--     'nvim-tree/nvim-web-devicons',
--   },
--   config = function()
--     require("nvim-tree").setup {}
--   end
-- }

  use 'tpope/vim-repeat'
  use 'tpope/vim-surround'
  use 'm4xshen/autoclose.nvim'

  -- open nvim from terminal without nested session
  -- use {
  --     "samjwill/nvim-unception",
  --     setup = function()
  --         vim.g.unception_open_buffer_in_new_tab = true
  --     end
  -- }
  use 'willothy/flatten.nvim'

  -- manage files in regular vim buffer
  use {
    'stevearc/oil.nvim',
    config = function() require('oil').setup() end
  }

  -- git 
  use 'tpope/vim-fugitive'

  -- autosave
  use({
	"Pocco81/auto-save.nvim",
	config = function()
		 require("auto-save").setup {
			-- your config goes here
			-- or just leave it empty :)
		 }
	end,
  })

  -- fuzzy finder
  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.1',
    requires = { {'nvim-lua/plenary.nvim'} }
  }

  -- color theme
  use 'morhetz/gruvbox'
  -- use 'Mofiqul/dracula.nvim'
  -- use 'folke/tokyonight.nvim'
  -- use 'sainnhe/sonokai'

  -- configurations for Nvim LSP
  use 'neovim/nvim-lspconfig' 
  
  -- completion framework:
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'                            
  use 'hrsh7th/cmp-path'                              
  use 'hrsh7th/nvim-cmp' 
  use 'hrsh7th/cmp-nvim-lua'
  use 'hrsh7th/cmp-nvim-lsp-signature-help'

  -- code snippets
  use 'SirVer/ultisnips'
  use 'quangnguyen30192/cmp-nvim-ultisnips'

  -- language parsers
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }
  use "IndianBoy42/tree-sitter-just"

  -- rust 
  use 'simrat39/rust-tools.nvim'

  -- python
  use {
    'psf/black', branch = 'stable'
  }
  use({
    'python-rope/ropevim',
    ft = "python"
  })

end)

