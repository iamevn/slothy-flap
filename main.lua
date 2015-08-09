math.randomseed(os.time())
love.window.setMode(700, 700, {resizable=false, vsync=false})

-- run on load or on reset
function love.load()
    -- print("[q] or [esc] to quit\n[r] to restart\n[f] to toggle fullscreen\n\n←/→ to decrease/increase jump\n↑/↓ to increase/decrease gravity\n---------------------------")
    print("---------------------------\n[q] to quit\n[r] to restart\n[f] to toggle fullscreen\n[esc] to pause\n[space] to jump\n---------------------------")
    sloth = {
        x = 100,
        y = love.graphics.getHeight() * .6,
        v = 0,
        a = -2000,
        jumpv = 750,
        r = 25
    }
    MAXY = love.graphics.getHeight()
    ANGV = 700
    MINY = 0
    TIME = 0
    WALLSPEED = 0.005
    GAPSIZE = 200
    walls = {}
    score = 0
    paused = false
    timeUntilWalls = 3
    timeBetweenWalls = 1.5
    timeSinceLastWall = timeBetweenWalls
    lost = false
    font = love.graphics.newFont("GrilledCheeseBTNWide.ttf", 24)
    love.graphics.setFont(font)
end

function jump()
    sloth.v = sloth.jumpv
end

-- TODO: set this up so that changing the screen-size in the middle of play won't screw things up
function spawnWall()
    table.insert(walls, {
        x = love.graphics.getWidth(),
        gapY = math.random(love.graphics.getHeight() - GAPSIZE),
        cleared = false,
        timer = 0
    })
end

-- shifts each wall by the appropriate amount for each dt
-- also despawns walls that move off left side of screen
-- also temporarily checks fo sloth collisions but this will move elsewhere
function shiftWalls(dt)
    for i, w in ipairs(walls) do
        w.timer = w.timer + dt
        if w.timer >= WALLSPEED then
            w.timer = w.timer - WALLSPEED
            w.x = w.x - 1
            if not w.cleared and w.x < sloth.x then 
                wallPassed(w)
            end
            if w.x < 0 then
                table.remove(walls, i)
            end

            if w.x > sloth.x - sloth.r / 2 and w.x < sloth.x + sloth.r / 2 then
                if w.gapY > MAXY - sloth.y  - sloth.r or w.gapY + GAPSIZE < MAXY - sloth.y + sloth.r then
                    gameOver()
                end
            end
        end
    end
end

function wallPassed(w)
    w.cleared = true
    score = score + 1
    print("score: "..score)
end

function gameOver()
    print("Game Over")
    paused = true
    lost = true
end

function love.keypressed(key)
    if key == " " and not paused then
        jump()
    elseif key == "escape" then
        paused = not paused
    elseif key == "q" then
        love.event.push("quit")
    elseif key == "r" then
        love.load()
    elseif key == "f" then
        love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
    -- elseif key == "up" then
    --     sloth.a = sloth.a - 50
    --     print("gravity = ", sloth.a)
    -- elseif key == "down" then
    --     sloth.a = sloth.a + 50
    --     print("gravity = ", sloth.a)
    -- elseif key == "left" then
    --     sloth.jumpv = sloth.jumpv - 25
    --     print("jumpv = ", sloth.jumpv)
    -- elseif key == "right" then
    --     sloth.jumpv = sloth.jumpv + 25
    --     print("jumpv = ", sloth.jumpv)
    end
end

-- function love.mousepressed(x, y, button)
-- end

function love.resize(w, h)
    MAXY = love.graphics.getHeight()
end

function love.update(dt)
    if not paused then
        integrate(sloth, dt)

        shiftWalls(dt)

        -- count down until it's time to start spawning walls and then start spawning them every timeBetweenWalls
        if timeUntilWalls > 0 then
            timeUntilWalls = timeUntilWalls - dt
        else
            timeSinceLastWall = timeSinceLastWall + dt
            if timeSinceLastWall >= timeBetweenWalls then
                timeSinceLastWall = timeSinceLastWall - timeBetweenWalls
                spawnWall()
            end
        end
    end
end

function integrate(sloth, dt)
    sloth.y = sloth.y + sloth.v * dt
    sloth.v = sloth.v + sloth.a * dt

    --some bookkeeping to keep sloth onscreen
    if sloth.y < MINY + sloth.r then
        sloth.y = MINY + sloth.r
        sloth.v = 0
    elseif sloth.y > MAXY - sloth.r then
        sloth.y = MAXY - sloth.r
        sloth.v = 0
    end
end

-- draw text and graphics
function love.draw()
    local y = MAXY - sloth.y
    local x = sloth.x
    love.graphics.setColor(255,255,255)

    -- draw the 'sloth'
    love.graphics.circle("fill", x, y, sloth.r, 100)
    love.graphics.setColor(0,0,0)
    love.graphics.setLineWidth(3)
    love.graphics.line(linePos(x, y))

    -- draw the walls
    for i, w in ipairs(walls) do
        love.graphics.setColor(255,0,0)
        love.graphics.setLineWidth(20)
        love.graphics.line(w.x, 0, w.x, w.gapY)
        love.graphics.line(w.x, w.gapY + GAPSIZE, w.x, love.graphics.getHeight())

        love.graphics.setColor(255,255,255)
        love.graphics.setLineWidth(1)
        love.graphics.line(w.x, 0, w.x, w.gapY)
        love.graphics.line(w.x, w.gapY + GAPSIZE, w.x, love.graphics.getHeight())
    end

    love.graphics.setColor(255,255,255)
    -- text
    love.graphics.printf("score: "..score, 0, 1, love.graphics.getWidth(), "center")
    if paused then
        if lost then
            love.graphics.printf("game over\n[r]estart\n[q]uit", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
        else
            love.graphics.printf("paused\n[esc] to resume", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
        end
    end
end

-- line position is a function of velocity
-- when v = 0, line is horizontal
-- at v >= ANGV, line is tilted 45 degrees up
-- at v <= -ANGV, line is tilted 45 degrees down
function linePos(cx, cy)
    local angle = (math.pi / 4) * (sloth.v / ANGV)
    return {
        cx, cy,
        cx + sloth.r * math.cos(angle),
        cy - sloth.r * math.sin(angle)
    }
end


-- COLOR STUFF--

-- returns a random rgb color
function randColor()
    return {
        r = math.random(255), 
        g = math.random(255), 
        b = math.random(255), 
        a = 255
    }
end

-- returns table's r, g, b, and a components
function tableToColor(t)
    return t.r, t.g, t.b, t.a
end

-- convert hsv into rgb
function toRGB(h, s, v)
    if s <= 0 then
        return v, v, v
    end
    h, s, v = h / 256 * 6, s / 255, v /255
    local c = v * s
    local x = (1 - math.abs((h % 2) - 1)) * c
    local m, r, g, b = (v - c), 0, 0, 0
    if h < 1 then
        r, g, b = c, x, 0
        elseif h < 2 then
            r, g, b = x, c, 0
            elseif h < 3 then
                r, g, b = 0, c, x
                elseif h < 4 then
                    r, g, b = 0, x, c
                    elseif h < 5 then
                        r, g, b = x, 0, c
                    else
                        r, g, b = c, 0, x
                    end
                    return (r + m) * 255, (g + m) * 255, (b + m) * 255
                end

                -- convert rgb into hsv
                function toHSV(r, g, b)
                    r, g, b = r / 255, g / 255, b / 255
                    local min, max = math.min(r, g, b), math.max(r, g, b)
                    local del = max - min
                    local h, s, v = 0, 0, 0
                    v = max

                    if del ~= 0 then
                        s = del / max
                        d = {
                            r = (((max - r) / 6) + (del / 2)) / del,
                            g = (((max - g) / 6) + (del / 2)) / del,
                            b = (((max - b) / 6) + (del / 2)) / del
                        }
                        if r == max then
                            h = d.b - d.g
                            elseif g == max then
                                h = (1 / 3) + d.r - d.b
                                elseif b == max then
                                    h = (2 / 3) + d.g - d.r
                                end
                                if h < 0 then
                                    h = h + 1
                                    elseif h > 1 then
                                        h = h - 1
                                    end
                                end
                                return h * 255, s * 255, v * 255
                            end

                            -- returns rgba for opposite color
                            function oppositeColor(r, g, b, a)
                                local h, s, v = toHSV(r, g, b)
                                h = (h + (256 / 2)) % 256
                                r, g, b = toRGB(h, s, v)
                                return r, g, b, a
                            end
