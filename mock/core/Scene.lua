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
	self.FLAG_EDITOR_SCENE = false
	self.running = false
	self.arguments       = {}
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

	--action groups direclty attached to game.actionRoot
	self.globalActionGroups = {} 

	return self
end

function Scene:getConfig( key )
	return self.config[ key ]
end

function Scene:isEditorScene()
	return self.FLAG_EDITOR_SCENE
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

	self:resetActionRoot()

	self:initLayers()
	self:initPhysics()
	self:initManagers()

	if self.onLoad then self:onLoad() end

	_stat( 'Initialize Scene' )

	if not self.FLAG_EDITOR_SCENE then
		emitSignal( 'scene.init', self )
	end
	
	self:reset()

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
	for i, globalManager in ipairs( getGlobalManagerRegistry() ) do
		globalManager:onSceneInit( self )
	end

end

function Scene:reset()
	self:resetActionRoot()
	for key, manager in pairs( self.managers ) do
		manager:reset()
	end
	for i, globalManager in ipairs( getGlobalManagerRegistry() ) do
		globalManager:onSceneReset( self )
	end
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
	for key, mgr in pairs( self:getManagers() ) do
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
	local newPendingStart = {}
	self.pendingStart = newPendingStart
	for entity in pairs( pendingStart ) do
		entity:start()
	end
	if next( newPendingStart ) then
		return self:flushPendingStart()
	else
		return self
	end
end

function Scene:threadMain( dt )
	_stat( 'entering scene main thread', self )

	for key, mgr in pairs( self:getManagers() ) do
		mgr:onStart()
	end

	-- first run
	for ent in pairs( self.entities ) do
		if not ent.parent then
			ent:start()
		end
	end
	self:flushPendingStart()
	
	-- 
	for key, mgr in pairs( self:getManagers() ) do
		mgr:postStart()
	end

	-- main loop
	_stat( 'entering scene main loop', self )
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

function Scene:getArgument( id, default )
	local v = self.arguments[ id ]
	if v == nil then return default end
	return v
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
--Action control
--------------------------------------------------------------------
function Scene:resetActionRoot()
	_stat( 'scene action root reset' )

	self.actionRoot = MOAICoroutine.new()
	self.actionRoot:setDefaultParent( true )
	self.actionRoot:run(
		function()
			while true do
				coroutine.yield()
			end
		end	
	)
	self.actionRoot:attach( self:getParentActionRoot() )

	_stat( 'scene timer reset ')
	self.timer   = MOAITimer.new()
	self.timer:setMode( MOAITimer.CONTINUE )
	self.timer:attach( self.actionRoot )

	_stat( 'global action group reset' )
	for id, gg in pairs( self.globalActionGroups ) do
		gg:clear()
		gg:stop()
	end
	self.globalActionGroups = {}

	_stat( 'scene action priority group reset' )
	for i, g in ipairs( self.actionPriorityGroups ) do
		g:clear()
		g:stop()
	end
	self.actionPriorityGroups = {}
	local root = self.actionRoot
	for i = 8, -8, -1 do
		local group = MOAIAction.new()
		group:setAutoStop( false )
		group:attach( root )
		group.priority = i
		self.actionPriorityGroups[ i ] = group
	end

end

function Scene:getActionRoot()
	return self.mainThread
end

function Scene:getParentActionRoot()
	return game:getActionRoot()
end

function Scene:getGlobalActionGroup( id, affirm )
	affirm = affirm ~= false
	local group = self.globalActionGroups[ id ]
	if (not group) and affirm then
		group = MOAIAction.new()
		group:setAutoStop( false )
		group:attach( self:getParentActionRoot() )
		self.globalActionGroups[ id ] = group
	end

	return group
end

function Scene:attachGlobalAction( id, action )
	assert( type( id ) == 'string', 'invalid global action group ID' )
	local group = self:getGlobalActionGroup( id )
	action:attach( group )
	return action
end

function Scene:pauseGlobalActionGroup( id, paused )
	local group = self:getGlobalActionGroup( id, true )
	group:pause( paused )
end

function Scene:isGlobalActionGroupPaused( id )
	local group = self:getGlobalActionGroup( id, false )
	if not group then return false end
	return group:isPaused()
end

function Scene:pause( paused )
	self.actionRoot:pause( paused ~= false )
end

function Scene:resume( )
	return self:pause( false )
end

function Scene:setThrottle( t )
	self.throttle = t
	self.actionRoot:throttle( t or 1 )
end

function Scene:getThrottle()
	return self.throttle
end

function Scene:setActionPriority( action, priority )
	local group = self.actionPriorityGroups[ priority ]
	action:attach( group )
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
	timer:attach( self:getActionRoot() )
	return timer
end


--------------------------------------------------------------------
--Flow Control
--------------------------------------------------------------------
function Scene:start()
	_stat( 'scene start', self )
	if self.running then return end
	if not self.initialized then self:init() end
	self.running = true
	self.mainThread = MOAICoroutine.new()
	self.mainThread:setDefaultParent( true )
	self.mainThread:run( function()
		return self:threadMain()
	end)
	self.mainThread:attach( self:getParentActionRoot() )

	_stat( 'mainthread scene start' )
	self:setActionPriority( self.mainThread, 0 )
	
	_stat( 'box2d scene start' )
	self:setActionPriority( self.b2world, 1 )

	local onStart = self.onStart
	if onStart then onStart( self ) end
	_stat( 'scene start ... done' )
end


function Scene:stop()
	if not self.running then return end
	self.running = false
	self.mainThread:stop()
	self.mainThread = false
	self.actionRoot:stop()
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
	_stat( 'clearing scene' )
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
	self.arguments = {}
	self.userObjects = {}
	
	for i, globalManager in ipairs( getGlobalManagerRegistry() ) do
		globalManager:onSceneClear( self )
	end

	if not self.FLAG_EDITOR_SCENE then
		emitSignal( 'scene.clear', self )
	end
end

function Scene:getRootGroup()
	return self.rootGroup
end

local function _collectEntityGroups( parentGroup, collected )
	for group in pairs( parentGroup.childGroups ) do
		collected[ group ] = true
		_collectEntityGroups( group, collected )
	end
	return collected
end

function Scene:collectEntityGroups()
	local groups = _collectEntityGroups( self.rootGroup, {} )
	return groups
end


Scene.add = Scene.addEntity

--------------------------------------------------------------------
--PHYSICS
--------------------------------------------------------------------

function Scene:initPhysics()
	local option = game and game.physicsOption or table.simplecopy( DefaultPhysicsWorldOption )

	local world
	if option.world and _G[ option.world ] then
		
		local worldClass = rawget( _G, option.world )
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
