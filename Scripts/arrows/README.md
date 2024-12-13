# Arrows System

A Hammerspoon module that enhances arrow key navigation with visual feedback, sound effects, and vim-style key support.

## Features

- 🎯 Visual feedback for arrow key and vim-style navigation
- 🔊 Sound effects with different tones for arrow and vim keys
- ⌨️ Vim-style navigation support (h, j, k, l)
- 🎉 Celebration animations for using both styles
- 🎨 Customizable appearance and animations
- 🔇 Silent mode toggle with double-escape
- 🖱️ Draggable feedback window
- 🌗 Dark mode support
- 👀 High contrast mode support

## Installation

1. Place this directory in your Hammerspoon configuration directory:
   ```
   ~/.hammerspoon/Scripts/arrows/
   ```

2. Create a sounds directory and add the required sound files:
   ```
   ~/.hammerspoon/sounds/
   ├── up.wav
   ├── down.wav
   ├── left.wav
   ├── right.wav
   ├── up_deeper.wav
   └── dissonant/
       ├── up.wav
       ├── down.wav
       ├── left.wav
       └── right.wav
   ```

3. Add to your `init.lua`:
   ```lua
   local arrows = require("arrows")
   arrows.init()
   ```

## Usage

### Basic Navigation
- Use arrow keys for normal navigation
- Use Hyper + hjkl for vim-style navigation
  - Hyper = Command + Control + Option + Shift
- Press Escape twice quickly to toggle sound effects

### Advanced Features
- Drag the feedback window to reposition it
- Try using both arrow and vim keys for the same direction to trigger celebrations
- Window position persists between sessions

### Configuration
You can customize the initialization with options:
```lua
arrows.init({
    test = true,     -- Run integration tests on startup
    strict = true    -- Fail initialization if any component fails
})
```

## Development

### Directory Structure
```
arrows/
├── init.lua          # Main entry point
├── model.lua         # Data and styling configurations
├── view.lua          # HTML generation and templates
├── controller.lua    # Window management and coordination
├── utils/
│   ├── sound.lua    # Sound management
│   └── animation.lua # Animation utilities
└── test.lua         # Integration tests
```

### Testing
Run the test suite:
```lua
local arrows = require("arrows")
arrows.test()
```

Debug current state:
```lua
arrows.debug()
```

### Components

#### Model
- Defines data structures and configurations
- Contains styling rules and constants
- Manages key mappings and enums

#### View
- Generates HTML for the feedback window
- Handles styling and templates
- Supports dark mode and accessibility

#### Controller
- Manages window lifecycle
- Handles keyboard events
- Coordinates components
- Manages state

#### Utils
- Sound: Handles audio feedback and muting
- Animation: Manages visual effects and celebrations

## Troubleshooting

1. No sound effects:
   - Check sound files exist in the correct location
   - Verify system audio is working
   - Try toggling silent mode with double-escape

2. Window not appearing:
   - Check Hammerspoon has accessibility permissions
   - Verify required modules are available
   - Run `arrows.debug()` to check state

3. Vim keys not working:
   - Verify Hyper key combination
   - Check key mappings in model.lua
   - Run integration tests

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run the test suite
5. Submit a pull request

## License

MIT License - See LICENSE file for details 