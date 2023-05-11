
return require('packer').startup(function(use)	
  use 'wbthomason/packer.nvim'

  -- File explorer
  use 'nvim-tree/nvim-tree.lua'
  use 'nvim-tree/nvim-web-devicons'

  -- git 
  use 'tpope/vim-fugitive'

  -- Autosave
  use({
	"Pocco81/auto-save.nvim",
	config = function()
		 require("auto-save").setup {
			-- your config goes here
			-- or just leave it empty :)
		 }
	end,
  })

  -- Fuzzy finder
  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.1',
    requires = { {'nvim-lua/plenary.nvim'} }
  }

  -- Color theme
  use 'morhetz/gruvbox'

  -- Configurations for Nvim LSP
  use 'neovim/nvim-lspconfig' 
  
  -- Completion framework:
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'                            
  use 'hrsh7th/cmp-path'                              
  use 'hrsh7th/nvim-cmp' 
  use 'hrsh7th/cmp-nvim-lua'
  use 'hrsh7th/cmp-nvim-lsp-signature-help'

  -- Code snippets
  use 'SirVer/ultisnips'
  use 'quangnguyen30192/cmp-nvim-ultisnips'

  -- Language parsers
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }
  use "IndianBoy42/tree-sitter-just"

  -- Rust 
  use 'simrat39/rust-tools.nvim'

  -- Python
  use {
    'psf/black', branch = 'stable'
  }

end)

