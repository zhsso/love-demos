local PI = 3.14159

local rects = {
    {
        x = 150,
        y = 100,
        width = 100,
        height = 100,
        angle = 60 / 180 * PI,
    },{
        x = 200,
        y = 150,
        width = 100,
        height = 100,
        angle = 45 / 180 * PI
    },{
        x = 150,
        y = 250,
        width = 100,
        height = 100,
        angle = 30 / 180 * PI
    }
}

local speed = {
	x = 0,
	y = 0,
}


local function calcDistance(a, b)
    return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)
end


local function crossProduct(a, b)
    return a.x*b.y - a.y*b.x
end


local function normalProduct(a, b)
    local la = math.sqrt(a.x * a.x + a.y * a.y)
    local lb = math.sqrt(b.x * b.x + b.y * b.y)
    return (a.x * b.x + a.y * b.y) / (la * lb)
end


local function drawOrginRect()
    love.graphics.translate(-200, -100)
    for _, rect in ipairs(rects) do
        for _, point in ipairs(rect.points) do
            love.graphics.line(point.line[1].x, point.line[1].y, point.line[2].x, point.line[2].y)
        end
    end
end


local function calcSectPoint(from1, to1, from2, to2)
    local x1, y1, x2, y2 = from1.x, from1.y, to1.x, to1.y
    local x3, y3, x4, y4 = from2.x, from2.y, to2.x, to2.y

    local d1 = (x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1)
    local d2 = (x2 - x1) * (y4 - y1) - (x4 - x1) * (y2 - y1)
    local d3 = (x4 - x3) * (y1 - y3) - (x1 - x3) * (y4 - y3)
    local d4 = (x4 - x3) * (y2 - y3) - (x2 - x3) * (y4 - y3)

    if d1 * d2 <= 0 and d3 * d4 <= 0 then
        local x = ((x1 * y2 - x2 * y1) * (x3 - x4)) - ((x3 * y4 - x4 * y3) * (x1 - x2))
        local d = ((x1 - x2) * (y3 - y4) - (x3 - x4) * (y1 - y2))
        local y = ((x1 * y2 - x2 * y1) * (y3 - y4)) - ((x3 * y4 - x4 * y3) * (y1 - y2))
        x = x / d
        y = y / d
        if math.abs(d) < 0.001 then return end

        local ret = (x - from1.x) * (x - to1.x) + (y - from1.y) * (y - to1.y)

        if ret > 0 then
            return
        end

        return {
            x = x,
            y = y
        }
    end
end


local function getRotateAngle(b, a)
    local f = { x = a[2].x - a[1].x, y = a[2].y - a[1].y}
    local t = { x = b[2].x - b[1].x,  y = b[2].y - b[1].y}

    local cp = crossProduct(f, t)
    local np = normalProduct(f, t)

    local angle = math.acos(np)
    if cp > 0 then
        angle = PI + angle
    end

    if math.abs(cp) < 0.01 and np > 0 then
        angle = PI
    end
    return angle
end


step = 100
showInfo = true
local function calcOutterLine()
    love.graphics.translate(200, 100)
    local points = {}
    for rectId, rect in ipairs(rects) do
        local x, y, width, height, angle = rect.x, rect.y, rect.width, rect.height, rect.angle
        local p1 = {
            rectId = rectId,
            x = x,
            y = y,
            altNext = {}
        }

        local p2 = {
            rectId = rectId,
            x = x + width * math.cos(angle),
            y = y + height * math.sin(angle),
            altNext = {}
        }

        local p3 = {
            rectId = rectId,
            altNext = {}
        }

        local p4 = {
            rectId = rectId,
            x = x - width * math.sin(angle),
            y = y + height * math.cos(angle),
            altNext = {}
        }

        p3.x = p2.x - p1.x + p4.x
        p3.y = p2.y - p1.y + p4.y

        p1.next = {{point = p2, line = { p1, p2} }}
        p1.line = {p1, p2}
        p2.next = {{point = p3, line = { p2, p3} }}
        p2.line = {p2, p3}
        p3.next = {{point = p4, line = { p3, p4} }}
        p3.line = {p3, p4}
        p4.next = {{point = p1, line = { p4, p1} }}
        p4.line = {p4, p1}

        
        p1.pre = {p4}
        p2.pre = {p1}
        p3.pre = {p2}
        p4.pre = {p3}
        rect.points = {p1, p2, p3, p4}
        points[#points + 1] = p1
        points[#points + 1] = p2
        points[#points + 1] = p3
        points[#points + 1] = p4
    end
    
    for i = 1, #points, 1 do
        local pi = points[i]
        for j = i + 1, #points, 1 do
            local pj = points[j]
            if pi.rectId ~= pj.rectId then
                local sp = calcSectPoint(pi, pi.next[1].point, pj, pj.next[1].point)
                if sp then
                    sp.next = {}
                    sp.pre = {}
                    pi.altNext[#pi.altNext + 1] = sp
                    pj.altNext[#pj.altNext + 1] = sp
                end
            end
        end
    end

    for _, point in ipairs(points) do
        if #point.altNext > 0 then
            table.sort(point.altNext, function(a, b)
                return calcDistance(a, point) < calcDistance(b, point)
            end)
                
            local nextP = point.next[1].point
            local anchor = point

            nextP.pre = {point.altNext[#point.altNext]}

            anchor.next = {}
            
            for _, p in ipairs(point.altNext) do
                anchor.next[#anchor.next + 1] = {point = p, line = point.line}
                p.pre[#p.pre + 1] = anchor
                anchor = p
            end
            anchor.next[#anchor.next + 1] = { point = nextP, line = point.line }
        end
    end

    table.sort(points, function(a, b)
        if a.x < b.x then return true end
        if a.x > b.x then return false end
        return a.y < b.y
    end)

    local beginP = points[1]
    
    local anchor = beginP
    local preP = beginP.pre[1]
    
    while not anchor.isCalc do
        table.sort(anchor.next, function(a, b)
            local aa = getRotateAngle(preP.next[1].line, a.line)
            local ab = getRotateAngle(preP.next[1].line, b.line)
            return aa > ab
        end)
        
        anchor.next[1].point.pre[1] = anchor
        anchor.isCalc = true
        preP = anchor
        anchor = anchor.next[1].point
    end
    

    local drawCnt = 1
    anchor = beginP
    while not anchor.isDraw do
        if drawCnt < step then
            love.graphics.line(anchor.x, anchor.y, anchor.next[1].point.x, anchor.next[1].point.y)
            drawCnt = drawCnt + 1
            if drawCnt == step and showInfo then
                for _, next in ipairs(anchor.next[1].point.next) do
                    love.graphics.circle("fill", next.point.x, next.point.y, 2)
                end
            end
        end
        anchor.isDraw = true
        anchor = anchor.next[1].point
    end
    
    if step > drawCnt then
        step = drawCnt
    end
end

local function drawOutterLine()
    calcOutterLine()
end


local selectedRect = 0
local keyMoveSpeed = 1

function love.update(dt)
    local rect = rects[selectedRect]
    if rect then
	rect.x = rect.x + speed.x
	rect.y = rect.y + speed.y
	step = 100
    end
end


function love.draw()
    drawOutterLine()
    drawOrginRect()
end


function love.keypressed(k)
    if k == "n" then
        step = step + 1
    elseif k == "p" then
        step = step - 1
        if step < 0 then step = 0 end
    elseif k == "i" then
        showInfo = not showInfo
    end
        
    if k == "w" then
	    speed = {x = 0, y = -keyMoveSpeed}
        step = 100
    elseif k == "s" then
	    speed = {x = 0, y = keyMoveSpeed}
        step = 100
    elseif k == "a" then
	    speed = {x = -keyMoveSpeed, y = 0}
        step = 100
    elseif k == "d" then
	    speed = {x = keyMoveSpeed, y = 0}
        step = 100
    elseif k == "q" then
	    speed = {x = 0, y = 0}
        step = 100
    end
end


function love.mousemoved( x, y, dx, dy, istouch )
    for indexId, rect in pairs(rects) do
        if (x > rect.x and y > rect.y and x < rect.x + rect.width and y < rect.y + rect.height) then
            selectedRect = indexId
            break
        end
    end
end
