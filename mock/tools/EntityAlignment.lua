module 'mock'

local min, max = math.min, math.max
function alignEntitiesLeft( entities )
	local bx0 = false
	for i, entity in ipairs( entities ) do
		local x0, y0, z0, x1, y1, z1 = entity:getWorldBounds()
		bx0 = bx0 and min( bx0, x0 ) or x0
	end
	for i, entity in ipairs( entities ) do
		local x0, y0, z0, x1, y1, z1 = entity:getWorldBounds()
		local x, y, z = entity:getWorldLoc()
		local dx = x - x0
		entity:setWorldLoc( bx0 + dx, y, z )
	end
end

function alignEntitiesRight( entities )
	local bx1 = false
	for i, entity in ipairs( entities ) do
		local x0, y0, z0, x1, y1, z1 = entity:getWorldBounds()
		bx1 = bx1 and max( bx1, x1 ) or x1
	end
	for i, entity in ipairs( entities ) do
		local x0, y0, z0, x1, y1, z1 = entity:getWorldBounds()
		local x, y, z = entity:getWorldLoc()
		local dx = x - x1
		entity:setWorldLoc( bx1 + dx, y, z )
	end
end

function alignEntitiesHCenter( entities )
	local bx0, bx1 = false, false
	for i, entity in ipairs( entities ) do
		local x0, y0, z0, x1, y1, z1 = entity:getWorldBounds()
		bx0 = bx0 and min( bx0, x0 ) or x0
		bx1 = bx1 and max( bx1, x1 ) or x1
	end
	local cx = ( bx0 + bx1 ) / 2
	for i, entity in ipairs( entities ) do
		local x0, y0, z0, x1, y1, z1 = entity:getWorldBounds()
		local x, y, z = entity:getWorldLoc()
		local dx = x - ( x0 + x1 ) / 2
		entity:setWorldLoc( cx + dx, y, z )
	end
end

function alignEntitiesTop( entities )
	local by1 = false
	for i, entity in ipairs( entities ) do
		local x0, y0, z0, x1, y1, z1 = entity:getWorldBounds()
		by1 = by1 and max( by1, y1 ) or y1
	end
	for i, entity in ipairs( entities ) do
		local x0, y0, z0, x1, y1, z1 = entity:getWorldBounds()
		local x, y, z = entity:getWorldLoc()
		local dy = y - y1
		entity:setWorldLoc( x, by1 + dy, z )
	end
end

function alignEntitiesBottom( entities )
	local by0 = false
	for i, entity in ipairs( entities ) do
		local x0, y0, z0, x1, y1, z1 = entity:getWorldBounds()
		by0 = by0 and min( by0, y0 ) or y0
	end
	for i, entity in ipairs( entities ) do
		local x0, y0, z0, x1, y1, z1 = entity:getWorldBounds()
		local x, y, z = entity:getWorldLoc()
		local dy = y - y0
		entity:setWorldLoc( x, by0 + dy, z )
	end
end

function alignEntitiesVCenter( entities )
	local by0, by1 = false, false
	for i, entity in ipairs( entities ) do
		local x0, y0, z0, x1, y1, z1 = entity:getWorldBounds()
		by0 = by0 and min( by0, y0 ) or y0
		by1 = by1 and max( by1, y1 ) or y1
	end
	local cy = ( by0 + by1 ) / 2
	for i, entity in ipairs( entities ) do
		local x0, y0, z0, x1, y1, z1 = entity:getWorldBounds()
		local x, y, z = entity:getWorldLoc()
		local dy = y - ( y0 + y1 ) / 2
		entity:setWorldLoc( x, cy + dy, z )
	end
end

function pushEntityTogetherLeft( entities )
	--sort entities in bound x
	--TODO
end

function pushEntityTogetherRight( entities )
	--sort entities in bound x
	--TODO
end

function pushEntityTogetherTop( entities )
	--sort entities in bound y
	--TODO
end

function pushEntityTogetherBottom( entities )
	--sort entities in bound y
	--TODO
end


function alignEntities( entities, mode )
	if mode == 'align_left' then
		return alignEntitiesLeft( entities )
	elseif mode == 'align_right' then
		return alignEntitiesLeft( entities )
	elseif mode == 'align_hcenter' then
		return alignEntitiesHCenter( entities )
	end
end