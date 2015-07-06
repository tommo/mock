module 'mock'

--------------------------------------------------------------------
CLASS: ShakeController ( Behaviour )
	:MODEL{}
registerComponent( 'ShakeController', ShakeController )


function ShakeController:__init()
	self.shakeSources = {}
end

function ShakeController:pushShakeSource( src )
	self.shakeSources[ src ] = true
	if not self.threadShaking then
		self.threadShaking = self:addCoroutine( 'actionShaking' )
	end
	return src
end

function ShakeController:pushShakeSourceX( scale, duration )
	local src = ShakeSourceX()
	src:setScale( scale )
	src:setDuration( duration )
	return self:pushShakeSource( src )
end

function ShakeController:pushShakeSourceY( scale, duration )
	local src = ShakeSourceY()
	src:setScale( scale )
	src:setDuration( duration )
	return self:pushShakeSource( src )
end

function ShakeController:pushShakeSourceXY( scale, duration )
	local src = ShakeSourceXY()
	src:setScale( scale )
	src:setDuration( duration )
	return self:pushShakeSource( src )
end


function ShakeController:pushShakeSourceXYRot( scale, duration )
	local src = ShakeSourceXYRot()
	src:setScale( scale )
	src:setDuration( duration )
	return self:pushShakeSource( src )
end

function ShakeController:pushShakeSourceDirectional( nx, ny, nz, duration )
	local src = ShakeSourceDirectional()
	src:setScale( nx, ny, nz )
	src:setDuration( duration )
	return self:pushShakeSource( src )
end

function ShakeController:clear()
	self.shakeSources = {}
end

function ShakeController:actionShaking()
	local target = self:getEntity()
	local px,py,pz = target:getPiv()
	local dt = 0
	while true do
		local sources = self.shakeSources
		local stopped = {}
		local x, y, z = 0,0,0
		for src in pairs( sources ) do
			local dx, dy, dz = src:update( dt )
			if not dx then --dead
				stopped[ src ] = true
			else
				if dx then x = x + dx end
				if dy then y = y + dy end
				if dz then z = z + dz end
			end
		end
		target:setPiv( px+x,py+y,py+z )
		for s in pairs( stopped ) do
			sources[ s ] = nil
		end

		if not next( sources ) then break end
		dt = coroutine.yield()
	end
	target:setPiv( px, py, pz )
	self.threadShaking = false
end


--------------------------------------------------------------------
CLASS: ShakeSource ()
function ShakeSource:__init()
	self.time  = 0
	self.noise = 0.2
	self.duration = 1
	self.active = true
end

function ShakeSource:stop()
	self.active = false
end

function ShakeSource:getDuration()
	return self.duration
end

function ShakeSource:setDuration( d )
	self.duration = d
end

function ShakeSource:setNoise( noise )
	self.noise = noise
end

function ShakeSource:update( dt )
	if not self.active then return false end
	self.time = self.time + dt
	if self.time > self.duration then
		return false
	end
	return self:onUpdate( self.time )
end

function ShakeSource:onUpdate( t )
end


--------------------------------------------------------------------
CLASS: ShakeSourceX ( ShakeSource )
	:MODEL{}

function ShakeSourceX:__init()
	self.scale = 5
	self.negative = false
end

function ShakeSourceX:setScale( scale )
	self.scale = scale
end

function ShakeSourceX:onUpdate( t )
	local k = 1 - t/self.duration
	self.negative = not self.negative
	local dx = self.scale * k * ( 1 + noise( self.noise ) )
	if self.negative then
		dx = - dx
	end
	return dx
end


--------------------------------------------------------------------
CLASS: ShakeSourceY ( ShakeSource )
	:MODEL{}

function ShakeSourceY:__init()
	self.scale = 5
	self.negative = false
end

function ShakeSourceY:setScale( scale )
	self.scale = scale
end

function ShakeSourceY:onUpdate( t )
	local k = 1 - t/self.duration
	self.negative = not self.negative
	local dy = self.scale * k * ( 1 + noise( self.noise ) )
	if self.negative then
		dy = - dy
	end
	return 0, dy
end

--------------------------------------------------------------------
CLASS: ShakeSourceXY ( ShakeSource )
	:MODEL{}

function ShakeSourceXY:__init()
	self.scale = 5
	self.nx = true
	self.ny = false
end

function ShakeSourceXY:setScale( scale )
	self.scale = scale
end

function ShakeSourceXY:onUpdate( t )
	local k = 1 - t/self.duration
	self.nx = not self.nx
	self.ny = not self.ny
	local dx = self.scale * k * ( 1 + noise( self.noise ) )
	if self.nx then
		dx = - dx
	end
	local dy = self.scale * k * ( 1 + noise( self.noise ) )
	if self.ny then
		dy = - dy
	end
	return dx, dy
end


--------------------------------------------------------------------
CLASS: ShakeSourceXYRot ( ShakeSource )
	:MODEL{}

function ShakeSourceXYRot:__init()
	self.scale = 5
	self.dir = 0
end

function ShakeSourceXYRot:setScale( scale )
	self.scale = scale
end

function ShakeSourceXYRot:onUpdate( t )
	local k = 1 - t/self.duration
	self.dir = self.dir + rand( 90, 180 )
	local nx, ny = math.cosd( self.dir ), math.sind( self.dir )
	
	local dx = self.scale * k * ( 1 + noise( self.noise ) ) * nx
	local dy = self.scale * k * ( 1 + noise( self.noise ) ) * ny
	return dx, dy
end


--------------------------------------------------------------------
CLASS: ShakeSourceDirectional ( ShakeSource )
	
function ShakeSourceDirectional:__init()
	self.negative = false
end

function ShakeSourceDirectional:setScale( x, y, z )
	self.sx = x or 0
	self.sy = y or 0
	self.sz = z or 0
end

function ShakeSourceDirectional:onUpdate( t )
	local k = ( 1 - t/self.duration ) * ( 1 + noise( self.noise ) )
	self.negative = not self.negative
	local dx = self.sx * k
	local dy = self.sy * k
	local dz = self.sz * k
	if self.negative then
		dx = -dx * 0.5
		dy = -dy * 0.5
		dz = -dz * 0.5
	end
	return dx, dy, dz
end

