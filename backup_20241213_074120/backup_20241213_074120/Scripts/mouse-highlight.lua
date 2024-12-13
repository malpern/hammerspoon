mouseCircle = nil
mouseCircleTimer = nil
mouseMoveTimer = nil

function mouseHighlight()
    -- Delete an existing highlight if it exists
    if mouseCircle then
        mouseCircle:delete()
        if mouseCircleTimer then
            mouseCircleTimer:stop()
        end
        if mouseMoveTimer then
            mouseMoveTimer:stop()
        end
    end

    -- Prepare a big red circle around the mouse pointer
    local canvasSize = 80 + 10  -- 80 for the circle diameter, 10 for the stroke width
    mouseCircle = hs.canvas.new({x = 0, y = 0, h = canvasSize, w = canvasSize})
    mouseCircle:appendElements({
        action = "stroke",
        type = "circle",
        radius = "40%",
        strokeColor = {red = 1, blue = 0, green = 0, alpha = 1},
        fillColor = {alpha = 0},
        strokeWidth = 10
    })
    mouseCircle:show()

    -- Function to update the position of the circle
    local function updateCirclePosition()
        local mousepoint = hs.mouse.absolutePosition()
        mouseCircle:frame({x = mousepoint.x - canvasSize / 2, y = mousepoint.y - canvasSize / 2, h = canvasSize, w = canvasSize})
    end

    -- Set a timer to update the circle position every 0.01 seconds
    mouseMoveTimer = hs.timer.doEvery(0.01, updateCirclePosition)

    -- Set a timer to delete the circle after 3 seconds
    mouseCircleTimer = hs.timer.doAfter(3, function()
        mouseCircle:delete()
        mouseCircle = nil
        mouseMoveTimer:stop()
        mouseMoveTimer = nil
    end)
end

hs.hotkey.bind({"control"}, "D", mouseHighlight)