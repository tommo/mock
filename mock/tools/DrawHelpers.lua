local draw = MOAIDraw
local pi, sin, cos, atan2 = math.pi, math.sin, math.cos, math.atan2
local D2R = pi/180
local R2D = 180/pi

local drawLine = draw.drawLine
local fillFan  = draw.fillFan

--------------------------------------------------------------------
--ARROW
--------------------------------------------------------------------
function MOAIDraw.drawArrow( x,y, x1,y1, size, angle, solid )
	drawLine( x,y, x1,y1 )
	local dx = x1 - x
	local dy = y1 - y
	local a0 = atan2( dy, dx )
	angle = angle or 30
	local angle = angle * D2R
	size =  size or 20
	local a2 = a0 + angle
	local a3 = a0 - angle
	local x2,y2 = x1 - size * cos( a2 ), y1 - size * sin( a2 )
	local x3,y3 = x1 - size * cos( a3 ), y1 - size * sin( a3 )
	if solid then
		fillFan( x1,y1, x2,y2, x3,y3 )
	else
		drawLine( x1,y1, x2,y2 )
		drawLine( x1,y1, x3,y3 )
	end
end

function MOAIDraw.fillArrow( x,y, x1,y1, size, angle )
	return MOAIDraw.drawArrow( x,y, x1,y1, size, angle, true )
end

--------------------------------------------------------------------
--
--------------------------------------------------------------------