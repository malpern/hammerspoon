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
]]

local M = {}

-- Type Definitions
---@class KeyType
---@field VIM string Vim-style navigation key
---@field ARROW string Arrow key navigation
---@field BACK string Back command key
M.KeyType = {
    VIM = "vim",
    ARROW = "arrow",
    BACK = "back"
}

---@class Direction
---@field UP string Up direction
---@field DOWN string Down direction
---@field LEFT string Left direction
---@field RIGHT string Right direction
---@field BACK string Back command
M.Direction = {
    UP = "up",
    DOWN = "down",
    LEFT = "left",
    RIGHT = "right",
    BACK = "back"
}

-- Visual Style Configuration
---@class Style
M.Style = {
    -- Color configurations for different states and elements
    COLORS = {
        VIM_BG = "rgba(30, 30, 30, 1)",      -- Background for vim commands
        ARROW_BG = "rgba(180, 0, 0, 1)",     -- Background for arrow keys
        VIM_SYMBOL = "white",                 -- Symbol color for vim commands
        VIM_LETTER = "#666666",              -- Letter color for vim commands
        ARROW_SYMBOL = "#4B0000",            -- Symbol color for arrow keys
        ARROW_LETTER = "white",              -- Letter color for arrow keys
        BACK_SYMBOL = "white",               -- Symbol color for back command
        BACK_TEXT = "#666666"                -- Text color for back command
    },
    
    -- Window dimensions and positioning
    WINDOW = {
        WIDTH = 90,                          -- Width of the display window
        HEIGHT = 120,                        -- Height of the display window
        MARGIN = 20,                         -- Margin from screen edges
        BORDER_RADIUS = 12,                  -- Border radius for the arrow block
        PADDING = 20                         -- Internal padding for the arrow block
    },
    
    -- Animation timing and configuration
    ANIMATION = {
        FADE_DURATION = 0.8,                 -- Duration of fade animation in seconds
        FADE_STEPS = 10,                     -- Number of steps in fade animation
        DISPLAY_DURATION = 2,                -- How long to display before fading
        TRANSITION_DELAY = 0.01              -- Delay between sound transitions
    },
    
    -- Font configurations
    FONT = {
        FAMILY = '"Proxima Nova", "SF Pro", sans-serif',
        SIZES = {
            SYMBOL = "1em",                  -- Size for direction symbols
            LETTER = "0.8em",                -- Size for key letters
            BACK = "0.65em"                  -- Size for back text
        },
        WEIGHT = "600"                       -- Font weight for all text
    }
}

-- Sound Configuration
---@class SoundConfig
M.Sound = {
    -- Volume levels
    VOLUME = {
        NORMAL = 0.2,                        -- Normal volume level
        MUTED = 0.0                          -- Muted volume level
    },
    
    -- Sound file paths (relative to sounds directory)
    PATHS = {
        NORMAL = "%s.wav",                   -- Pattern for normal sounds
        DISSONANT = "dissonant/%s.wav",      -- Pattern for dissonant sounds
        BACK = "up_deeper.wav"               -- Back command sound
    },
    
    -- Timing configurations
    TIMING = {
        DEBOUNCE = 0.1,                      -- Sound debounce time in seconds
        TRANSITION = 0.01                    -- Sound transition time in seconds
    }
}

-- Timing Configuration
---@class TimingConfig
M.Timing = {
    CELEBRATION = {
        TIMEOUT = 2.0,                       -- Celebration window timeout
        REPEAT_COUNT = 3,                    -- Number of celebration repeats
        REPEAT_DELAY = 0.1                   -- Delay between celebration repeats
    },
    
    KEY = {
        DEBOUNCE = 0.1,                      -- Key press debounce time
        DOUBLE_TAP = 0.3,                    -- Double-tap detection threshold
        HYPER_RESET = 0.1                    -- Hyper key reset delay
    }
}

-- Key Mapping Configuration
---@class KeyMapping
---@field vim string The vim key for this direction
---@field keycode number The keycode for this direction
M.KeyMappings = {
    [M.Direction.UP] = {vim = "k", keycode = 126},      -- Up arrow / k
    [M.Direction.DOWN] = {vim = "j", keycode = 125},    -- Down arrow / j
    [M.Direction.LEFT] = {vim = "h", keycode = 123},    -- Left arrow / h
    [M.Direction.RIGHT] = {vim = "l", keycode = 124},   -- Right arrow / l
    [M.Direction.BACK] = {vim = "b", keycode = 116}     -- Page Up / b
}

-- Special Key Codes
M.SpecialKeys = {
    ESCAPE = 53,                             -- Escape key code
    CELEBRATION = 35                         -- Celebration trigger key code (p)
}

-- State Configuration
---@class StateConfig
M.State = {
    -- Initial state
    INITIAL = {
        silentMode = false,                  -- Start with sound enabled
        isHyperGenerated = false,            -- Not generated by hyper key
        inKeySequence = false                -- Not in a key sequence
    },
    
    -- State transitions
    TRANSITIONS = {
        SILENT_TOGGLE = "silent_toggle",     -- Toggle silent mode
        KEY_PRESS = "key_press",             -- Key press event
        CELEBRATION = "celebration",          -- Celebration event
        RESET = "reset"                      -- Reset state
    }
}

return M 