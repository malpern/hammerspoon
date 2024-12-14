--[[
    Model configuration for the Arrows module
    
    This module defines all the data structures, configurations, and constants used
    throughout the Arrows system. It includes:
    
    - Type definitions (KeyType, Direction)
    - Visual styling (colors, dimensions, animations)
    - Key mappings and keyboard configurations
    - Sound settings
    - Timing configurations
    - State definitions

    Types:
    - All enums are string literals with predefined values
    - All style values must match their specified types exactly
    - All timing values are numbers in seconds
    - nil values are NOT valid for required fields
]]

local M = {}

-- Font configuration types
---@class FontSizes
---@field DEFAULT string Default size in em units
---@field BACK string Back button size in em units

---@class FontConfig
---@field FAMILY string Font family string
---@field WEIGHT string Font weight string
---@field SIZES { SYMBOL: FontSizes, LABEL: FontSizes } Size configurations

-- Color configuration types
---@class ColorSet
---@field DEFAULT string Default color in hex or rgba
---@field ARROW string Arrow key color in hex or rgba
---@field BACK? string Optional back button color

---@class ColorConfig
---@field BACKGROUND { DEFAULT: string, ARROW: string } Background colors
---@field SYMBOL ColorSet Symbol colors
---@field LABEL ColorSet Label colors

-- Window configuration types
---@class WindowConfig
---@field WIDTH number Window width in pixels
---@field HEIGHT number Window height in pixels
---@field MARGIN number Window margin in pixels
---@field BORDER_RADIUS number Border radius in pixels
---@field PADDING number Internal padding in pixels

-- Animation configuration types
---@class AnimationConfig
---@field FADE_DURATION number Duration in seconds
---@field FADE_STEPS number Number of fade steps
---@field DISPLAY_DURATION number Display time in seconds
---@field TRANSITION_DELAY number Delay in seconds

-- Timing configuration types
---@class KeyTiming
---@field HYPER_RESET number Time in seconds
---@field DOUBLE_PRESS number Time in seconds
---@field DEBOUNCE number Key press debounce time

---@class CelebrationTiming
---@field TIMEOUT number Time window in seconds
---@field DURATION number Duration in seconds
---@field REPEAT_COUNT number Number of times to repeat celebration
---@field REPEAT_DELAY number Delay between repeats in seconds

-- Sound configuration types
---@class SoundConfig
---@field VOLUME { NORMAL: number, MUTED: number } Volume levels
---@field PATHS { NORMAL: string, DISSONANT: string, BACK: string } Sound file paths

-- Core type definitions
---@class KeyType
---@field VIM "vim" Vim-style navigation key
---@field ARROW "arrow" Arrow key navigation
---@field BACK "back" Back command key
M.KeyType = {
	VIM = "vim",
	ARROW = "arrow",
	BACK = "back",
}

---@class Direction
---@field UP "up" Up direction
---@field DOWN "down" Down direction
---@field LEFT "left" Left direction
---@field RIGHT "right" Right direction
---@field BACK "back" Back command
M.Direction = {
	UP = "up",
	DOWN = "down",
	LEFT = "left",
	RIGHT = "right",
	BACK = "back",
}

-- Symbols and Labels
---@type table<string, string>
M.SYMBOLS = {
	[M.Direction.UP] = "⬆",
	[M.Direction.DOWN] = "⬇",
	[M.Direction.LEFT] = "⬅",
	[M.Direction.RIGHT] = "➡",
	[M.Direction.BACK] = "▲",
}

---@type table<string, string>
M.LABELS = {
	[M.Direction.UP] = "K",
	[M.Direction.DOWN] = "J",
	[M.Direction.LEFT] = "H",
	[M.Direction.RIGHT] = "L",
	[M.Direction.BACK] = "Back",
}

-- Visual Style Configuration
---@class Style
---@field FONT FontConfig Font configuration
---@field COLORS ColorConfig Color configuration
---@field WINDOW WindowConfig Window dimensions and positioning
---@field ANIMATION AnimationConfig Animation timing and configuration
M.Style = {
	-- Font configurations
	FONT = {
		FAMILY = '"Proxima Nova", "SF Pro", sans-serif',
		WEIGHT = "600",
		SIZES = {
			SYMBOL = {
				DEFAULT = "1em",
				BACK = "0.85em",
			},
			LABEL = {
				DEFAULT = "0.8em",
				BACK = "0.65em",
			},
		},
	},

	-- Color configurations for different states and elements
	COLORS = {
		BACKGROUND = {
			DEFAULT = "rgba(30, 30, 30, 1)", -- Dark gray for vim
			ARROW = "rgba(180, 0, 0, 1)", -- Red for arrow keys
		},
		SYMBOL = {
			DEFAULT = "white", -- Default symbol color
			ARROW = "#4B0000", -- Dark red for arrow keys
			BACK = "white", -- White for back command
		},
		LABEL = {
			DEFAULT = "#666666", -- Gray for vim
			ARROW = "white", -- White for arrow keys
			BACK = "#666666", -- Gray for back command
		},
	},

	-- Window dimensions and positioning
	WINDOW = {
		WIDTH = 90, -- Width of the display window
		HEIGHT = 120, -- Height of the display window
		MARGIN = 20, -- Margin from screen edges
		BORDER_RADIUS = 12, -- Border radius for the arrow block
		PADDING = 20, -- Internal padding for the arrow block
	},

	-- Animation timing and configuration
	ANIMATION = {
		FADE_DURATION = 0.8, -- Duration of fade animation in seconds
		FADE_STEPS = 10, -- Number of steps in fade animation
		DISPLAY_DURATION = 2.0, -- How long to display before fading
		TRANSITION_DELAY = 0.01, -- Delay between sound transitions
	},
}

-- Timing configurations
---@class Timing
---@field KEY KeyTiming Key press timing configuration
---@field CELEBRATION CelebrationTiming Celebration timing configuration
M.Timing = {
	KEY = {
		HYPER_RESET = 0.1, -- Time to reset hyper key state
		DOUBLE_PRESS = 0.3, -- Time window for double press
		DEBOUNCE = 0.1, -- Key press debounce time
	},
	CELEBRATION = {
		TIMEOUT = 1.0, -- Time window for celebration trigger
		DURATION = 2.0, -- How long celebration lasts
		REPEAT_COUNT = 3, -- Number of times to repeat celebration
		REPEAT_DELAY = 0.2, -- Delay between celebration repeats
	},
}

-- Initial state
---@class InitialState
---@field inKeySequence boolean Whether in a key sequence
---@field isHyperGenerated boolean Whether generated by hyper key
M.State = {
	INITIAL = {
		inKeySequence = false, -- Not in a key sequence
		isHyperGenerated = false, -- Not generated by hyper key
	},
}

-- Key mappings
---@class KeyMapping
---@field vim string The vim key for this direction
---@field keycode number The keycode for this direction
M.KeyMappings = {
	[M.Direction.UP] = { vim = "k", keycode = 126 }, -- Up arrow
	[M.Direction.DOWN] = { vim = "j", keycode = 125 }, -- Down arrow
	[M.Direction.LEFT] = { vim = "h", keycode = 123 }, -- Left arrow
	[M.Direction.RIGHT] = { vim = "l", keycode = 124 }, -- Right arrow
	[M.Direction.BACK] = { vim = "b", keycode = 116 }, -- Page Up
}

-- Special key codes
---@class SpecialKeys
---@field ESCAPE number Escape key code
---@field CELEBRATION number Up arrow for celebration
M.SpecialKeys = {
	ESCAPE = 53, -- Escape key code
	CELEBRATION = 126, -- Up arrow for celebration (same as UP direction)
}

-- Sound Configuration
M.Sound = {
	-- Volume levels
	VOLUME = {
		NORMAL = 0.2, -- Normal volume level
		MUTED = 0.0, -- Muted volume level
	},

	-- Sound file paths (relative to sounds directory)
	PATHS = {
		NORMAL = "%s.wav", -- Pattern for normal sounds
		DISSONANT = "dissonant/%s.wav", -- Pattern for dissonant sounds
		BACK = "up_deeper.wav", -- Back command sound
	},
}

return M
