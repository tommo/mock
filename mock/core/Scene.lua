module 'mock'


--------------------------------------------------------------------
--SCENE
--------------------------------------------------------------------
CLASS: 
	Scene ()
	:MODEL{
		Field 'EntityCount' :int() :readonly() :get( 'getEntityCount' );
		Field 'comment' :string() :widget( 'textbox' );
	}

function Scene:__init( option )
	self.active = false
	self.__editor_scene = false
	self.running = false
	self.arguments       = false
	self.layers          = {}
	self.layersByName    = {}
	self.entities        = {}
	self.entitiesByName  = {}

	self.pendingStart    = {}
	self.pendingDestroy  = {}
	self.laterDestroy    = {}
	self.pendingCall     = {}
	self.pendingDetach   = {}

	self.updateListeners = {}
	self.metaData        = {} 

	self.defaultCamera   = false
	self.option          = option

	self.throttle        = 1

	self.b2world         = false
	self.b2ground        = false
	self.actionPriorityGroups = {}

	self.config          = {}

	self.rootGroup       = EntityGroup()
	self.rootGroup.isRoot = true
	self.rootGroup.scene = self

	self.managers  = {}
	self.comment   = ""

	return self
end

function Scene:getConfig( key )
	return self.config[ key ]
end

function Scene:isEditorScene()
	return self.__editor_scene
end

--------------------------------------------------------------------
--COMMON
--------------------------------------------------------------------
function Scene:init()
	if self.initialized then return end 
	self.initialized  = true
	self.exiting = false
	self.active  = true
	self.userObjects = {}

	-- self.mainLayer = self:addLayer( 'main' )
	self:initLayers()
	self:initManagers()

	if self.onLoad then self:onLoad() end

	_stat( 'Initialize Scene' )

	self:resetTimer()

	self:setupBox2DWorld()
	if not self.__editor_scene then
		emitSignal( 'scene.init', self )
	end

end

function Scene:resetTimer()
	self.timer   = MOAITimer.new()
	self.timer:setMode( MOAITimer.CONTINUE )
	self:resetActionPriorityGroups()
end

function Scene:resetActionPriorityGroups()
	for i, g in ipairs( self.actionPriorityGroups ) do
		g:clear()
		g:stop()
	end
	self.actionPriorityGroups = {}
	for i = 8, -8, -1 do
		local group = MOAIAction.new()
		group:setAutoStop( false )
		group:attach( self.timer )
		group.priority = i
		self.actionPriorityGroups[ i ] = group
	end
end


function Scene:initLayers()
	local layers = {}
	local layersByName = {}
	local defaultLayer

	for i, l in ipairs( game.layers ) do
		local layer = l:makeMoaiLayer()
		layers[i] = layer
		layersByName[ layer.name ] = layer
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
	self.layersByName = layersByName
end

function Scene:initManagers()
	self.managers = {}
	local registry = getSceneManagerFactoryRegistry()
	local isEditorScene = self:isEditorScene()
	for i, fac in ipairs( registry ) do
		if not isEditorScene or fac:acceptEditorScene() then
			local manager = fac:create( self )
			if manager then
				manager._factory = fac
				manager._key = fac:getKey()
				manager:init( self )
				self.managers[ manager._key ] = manager
			end
		end
	end
end

function Scene:getActionRoot()
	return game:getActionRoot()
end

function Scene:getTime()
	return game:getTime()
end

function Scene:getManager( key )
	return self.managers[ key ]
end

function Scene:getManagers()
	return self.managers
end

function Scene:serializeConfig()
	local output = {}
	--common
	local commonData = {
		['comment'] = self.comment
	}
	output[ 'common' ] = commonData
	
	--managers
	local managerConfigData = {}
	for i, mgr in ipairs( self:getManagers() ) do
		local key = mgr:getKey()
		local data = mgr:serialize()
		if data then
			managerConfigData[ key ] = data
		end
	end
	output[ 'managers' ] = managerConfigData
	return output
end

function Scene:deserializeConfig( data )
	--common
	local commonConfigData = data[ 'common' ]
	if commonConfigData then
		self.comment = commonConfigData[ 'comment' ]
	end

	--managers
	local managerConfigData = data[ 'managers' ]
	if managerConfigData then
		for key, data in pairs( managerConfigData ) do
			local mgr = self:getManager( key )
			if mgr then
				mgr:deserialize( data )
			end
		end
	end
end

function Scene:flushPendingStart()
	if not self.running then return self end
	local pendingStart = self.pendingStart
	self.pendingStart = {}
	for entity in pairs( pendingStart ) do
		entity:start()
	end
	return self
end

function Scene:threadMain( dt )
	dt = 0
	local lastTime = self:getTime()
	while true do	
		local nowTime = self:getTime()
		if self.active then
			-- local dt = nowTime - lastTime
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
			for obj in pairs( self.updateListeners ) do
				local isActive = obj.isActive
				if not isActive or isActive( obj ) then
					obj:onUpdate( dt )
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

			self:flushPendingStart()

		--end of step update
		end
		
		--executeDestroyQueue()
		local pendingDetach = self.pendingDetach
		self.pendingDetach = {}
		for com in pairs( pendingDetach ) do
			local ent = com._entity
			if ent then
				ent:detach( com )
			end
		end

		local pendingDestroy = self.pendingDestroy
		self.pendingDestroy = {}
		for entity in pairs( pendingDestroy ) do
			if entity.scene then
				entity:destroyNow()
			end
		end

		dt = coroutine.yield()
		if self.exiting then 
			self:exitNow() 
		elseif self.exitingTime and self.exitingTime <= self:getTime() then
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

function Scene:setUserObject( id, obj )
	self.userObjects[ id ] = obj
end

function Scene:getUserObject( id )
	return self.userObjects[ id ]
end

function Scene:getPath()
	return self.path or false
end

function Scene:getArguments()
	return self.arguments
end

function Scene:setActionPriority( action, priority )
	local group = self.actionPriorityGroups[ priority ]
	action:attach( group )
end

function Scene:setMetaData( key, data )
	self.metaData[ key ] = data
end

function Scene:getMetaData( key, default )
	local v = self.metaData[ key ]
	if v == nil then return default end
	return v
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
	self.timer:pause( paused ~= false )
	self.mainThread:pause( paused )
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
function Scene:start()
	_stat( 'scene start' )
	if self.running then return end
	if not self.initialized then self:init() end
	self.running = true
	local onStart = self.onStart
	if onStart then onStart( self ) end
	
	self.mainThread = MOAICoroutine.new()
	self.mainThread:setDefaultParent( true )
	self.mainThread:run(
		function()
			for ent in pairs( self.entities ) do
				if not ent.parent then
					ent:start()
				end
			end
			return self:threadMain()
		end
	)
	
	_stat( 'mainthread scene start' )
	self:setActionPriority( self.mainThread, 0 )
	_stat( 'box2d scene start' )
	self:setActionPriority( self.b2world, 1 )

	_stat( 'scene timer start' )
	self.timer:attach( self:getActionRoot() )

end


function Scene:stop()
	if not self.running then return end
	self.running = false
	self:resetTimer()
	-- self.b2world:stop()
	self.mainThread:stop()
	self.mainThread = false

end



function Scene:exitLater(time)
	self.exitingTime = game:getTime() + time
end

function Scene:exit()
	_stat( 'scene exit' )
	self.exiting = true	
end

function Scene:exitNow()
	_codemark('Exit Scene: %s',self.name)
	self:stop()
	self.active  = false
	self.exiting = false
	if self.onExit then self.onExit() end
	self:clear()	
	emitSignal( 'scene.exit', self )	
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
	return self.layersByName[ name ]
	-- for i,l in pairs( self.layers ) do
	-- 	if l.name == name then return l end
	-- end
	-- return nil
end


--------------------------------------------------------------------
--Entity Control
--------------------------------------------------------------------
function Scene:setEntityListener( func )
	self.entityListener = func or false
end

function Scene:addEntity( entity, layer, group )
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
	group = group or entity._entityGroup or self.rootGroup
	group:addEntity( entity )
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
	local entityListener = self.entityListener
	if entityListener then
		self.entityListener = false
		entityListener( 'clear', keepEditorEntity )
	end
	local toRemove = {}
	_stat( 'pre clear', table.len( self.entities) )
	for e in pairs( self.entities ) do
		if not e.parent then
			if not ( keepEditorEntity and e.FLAG_EDITOR_OBJECT ) then
				toRemove[ e ] = true				
			end
		end
	end
	for e in pairs( toRemove ) do
		e:destroyWithChildrenNow()
	end
	_stat( 'post clear', table.len( self.entities) )
	
	--layers in Scene is not in render stack, just let it go
	self.laterDestroy    = {}
	self.pendDestroy     = {}
	self.pendingCall     = {}
	self.entitiesByName  = {}
	self.pendingStart    = {}

	self.rootGroup       = EntityGroup()
	self.rootGroup.scene = self
	self.rootGroup.isRoot = true

	self.defaultCamera   = false
	self.entityListener = entityListener
	self.arguments = false

	if not self.__editor_scene then
		emitSignal( 'scene.clear', self )
	end
end

function Scene:getRootGroup()
	return self.rootGroup
end


Scene.add = Scene.addEntity

--------------------------------------------------------------------
--PHYSICS
--------------------------------------------------------------------

function Scene:setupBox2DWorld()
	local option = game and game.physicsOption or table.simplecopy( DefaultPhysicsWorldOption )

	local world
	if option.world and _G[option.world] then
		
		local worldClass = rawget(_G, option.world)
		world = worldClass.new()
	else
		world = MOAIBox2DWorld.new()
	end

	if option.gravity then
		world:setGravity ( unpack(option.gravity) )
	end
	
	if option.unitsToMeters then
		world:setUnitsToMeters ( option.unitsToMeters )
	end
	
	local velocityIterations, positionIterations = option.velocityIterations, option.positionIterations
	velocityIterations = velocityIterations
	positionIterations = positionIterations
	world:setIterations ( velocityIterations, positionIterations )

	world:setAutoClearForces       ( option.autoClearForces )
	world:setTimeToSleep           ( option.timeToSleep )
	world:setAngularSleepTolerance ( option.angularSleepTolerance )
	world:setLinearSleepTolerance  ( option.linearSleepTolerance )
	self.b2world = world

	local ground = world:addBody( MOAIBox2DBody.STATIC )
	self.b2ground = ground

	return world
end

function Scene:getBox2DWorld()
	return self.b2world
end

function Scene:getBox2DWorldGround()
	return self.b2ground
end

function Scene:pauseBox2DWorld( paused )
	self.b2world:pause( paused )
end


function Scene:getEntityCount()
	return table.len( self.entities )
end
