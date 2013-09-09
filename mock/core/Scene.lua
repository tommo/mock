module 'mock'

--------------------------------------------------------------------
--SCENE
--------------------------------------------------------------------
CLASS: 
	Scene (Actor)
	:MODEL{
		
	}


function Scene:__init( option )
	self.active = false
	
	self.running = false

	self.layers          = {}
	self.entities        = {}
	self.entitiesByName  = {}

	self.pendingDestroy  = {}
	self.laterDestroy    = {}
	self.pendingCall     = {}

	self.updateListeners = {}
	self.metaData        = {} 

	self.defaultCamera   = false
	self.option          = option

	self.throttle        = 1

	return self
end


--------------------------------------------------------------------
--COMMON
--------------------------------------------------------------------
function Scene:init()
	if self.initialized then return end 
	self.initialized  = true

	self.exiting = false
	self.active  = true

	self.timer   = MOAITimer.new()
	self.timer:setMode( MOAITimer.CONTINUE )
	
	-- self.mainLayer = self:addLayer( 'main' )
	local layers = {}
	local defaultLayer
	
	for i, l in ipairs( game.layers ) do
		local layer = l:makeMoaiLayer()
		layers[i] = layer
		if l.default then
			defaultLayer = layer
		end
	end

	if defaultLayer then
		self.defaultLayer = defaultLayer
	else
		self.defaultLayer = layers[1]
	end

	assert( self.defaultLayer )
	self.layers = layers

	if self.onLoad then self:onLoad() end

	self.mainThread=MOAICoroutine.new()
	self.mainThread:run(function()
		return self:threadMain()
	end
	)

	self.timer:attach( self:getActionRoot() )
	self.timer:start()

end

function Scene:getActionRoot( root )
	return game.actionRoot
end

function Scene:threadMain( dt )
	
	local lastTime = game:getTime()
	while true do	
		if not self.running then self:start() end
		local nowTime = game:getTime()

		if self.active then
			local dt = nowTime -lastTime
			lastTime = nowTime
			
			--callNextFrame
			local pendingCall = self.pendingCall
			self.pendingCall = {}
			for i, t in ipairs( pendingCall ) do
				local func = t.func
				if type( func ) == 'string' then --method call
					local entity = t.object
					func = entity[ func ]
					func( entity, unpack(t) )
				else
					func( unpack(t) )
				end
			end

			--onUpdate
			for entity in pairs( self.updateListeners ) do
				if entity:isActive() then
					entity:onUpdate( dt )
				end
			end
			
			--destroy later
			local laterDestroy = self.laterDestroy
			for entity, time in pairs( laterDestroy ) do
				if nowTime >= time then
					entity:destroy()
					laterDestroy[ entity ] = nil
				end
			end

		--end of step update
		end

		--executeDestroyQueue()
		local pendingDestroy = self.pendingDestroy
		self.pendingDestroy = {}
		for entity in pairs( pendingDestroy ) do
			if entity.scene then
				entity:destroyNow()
			end
		end
		coroutine.yield()

		if self.exiting then 
			self:exitNow() 
		elseif self.exitingTime and self.exitingTime <= game:getTime() then
			self.exitingTime = false
			self:exitNow()
		end

	--end of main loop
	end
end

--obj with onUpdate( dt ) interface
function Scene:addUpdateListener( obj )
	--assert ( type( obj.onUpdate ) == 'function' )
	self.updateListeners[ obj ] = true
end

function Scene:removeUpdateListener( obj )
	self.updateListeners[ obj ] = nil
end

--------------------------------------------------------------------
--TIMER
--------------------------------------------------------------------
function Scene:getTime()
	--TODO: allow scene to have independent clock
	return self.timer:getTime()
end

function Scene:getSceneTimer()
	return self.timer
end

function Scene:createTimer( )
	local timer = MOAITimer.new()
	timer:attach( self.timer )
	return timer
end

function Scene:pause( paused )
	self.timer:pause( paused~=false )
end

function Scene:resume( )
	return self:pause( false )
end

function Scene:setThrottle( t )
	self.throttle = t
	self.timer:throttle( t or 1 )
end

function Scene:getThrottle()
	return self.throttle
end
--------------------------------------------------------------------
--Flow Control
--------------------------------------------------------------------
function Scene:enter( option )
	if self.active then return end
	_stat( 'Entering Scene: %s', self.name )
	self:init( self.option and self.option.actionRoot )
	self.active = true
	--callback onenter
	local onEnter = self.onEnter
	if onEnter then onEnter( self, option ) end
	emitSignal( 'scene.enter', self )	
end

function Scene:start()
	if self.running then return end
	self.running = true
	for ent in pairs( self.entities ) do
		if not ent.parent then
			ent:start()
		end
	end
end

function Scene:stop()
	if not self.running then return end
	self.running = false
end

function Scene:exitLater(time)
	self.exitingTime = game:getTime() + time
end

function Scene:exit(nextScene)
	self.exiting = true	
end

function Scene:exitNow()
	_codemark('Exit Scene: %s',self.name)
	self.active  = false
	self.exiting = false
	self.running = false
	self.timer:stop()
	emitSignal( 'scene.exit', self )
	if self.onExit then self.onExit() end
	self:clear()
end


--------------------------------------------------------------------
--Layer control
--------------------------------------------------------------------
--[[
	Layer in scene is only for placeholder/ viewport transform
	Real layers for render is inside Camera, which supports multiple viewport render
]]


function Scene:getLayer( name )
	if not name then return self.defaultLayer end
	for i,l in pairs( self.layers ) do
		if l.name == name then return l end
	end
	return nil
end


--------------------------------------------------------------------
--Entity Control
--------------------------------------------------------------------
function Scene:setEntityListener( func )
	self.entityListener = func or false
end

function Scene:addEntity( entity, layer )
	assert( entity )
	layer = layer or entity.layer or self.defaultLayer
	
	if type(layer) == 'string' then 
		local layerName = layer
		layer = self:getLayer( layerName )
		if not layer then 
			_error( 'layer not found:', layerName )			
			layer = self.defaultLayer
		end 
	end
	assert( layer )

	entity:_insertIntoScene( self, layer )	
	
	return entity
end

function Scene:addEntities( list, layer )
	for k, entity in pairs( list ) do
		self:addEntity( entity, layer )
		if type( k ) == 'string' then
			entity:setName( k )
		end
	end
end

function Scene:findEntity( name )
	return self.entitiesByName[ name ]
end

function Scene:changeEntityName( entity, oldName, newName )
	if oldName then
		if entity == self.entitiesByName[ oldName ] then
			self.entitiesByName[ oldName ]=nil
		end
	end
	if not self.entitiesByName[ newName ] then
		self.entitiesByName[ newName ] = entity
	end
end

function Scene:clear( keepEditorEntity )
	for e in pairs( self.entities ) do
		if not e.parent then
			if not ( keepEditorEntity and e.FLAG_EDITOR_OBJECT ) then
				e:destroyWithChildrenNow()	
			end
		end
	end

	--layers in Scene is not in render stack, just let it go
	-- self.layers          = {}
		
	self.laterDestroy    = {}
	self.pendDestroy     = {}
	self.pendingCall     = {}
	self.entitiesByName  = {}

	self.updateListeners = {}
	self.defaultCamera   = false
end

