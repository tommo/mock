module 'mock'

---------------------------------------------------------------------
CLASS: SQContextProvider ()
	:MODEL{}

function SQContextProvider:get( actor, contextId )
	return nil
end


local SQContextProviders = {}
function registerSQContextProvider( id, provider )
	SQContextProviders[ id ] = provider
end


--------------------------------------------------------------------
CLASS: SQActor ( Behaviour )
	:MODEL{
		Field 'name'     :string();
		Field 'script' :asset( 'sq_script' ) :getset( 'Script' );
		Field 'autoStart' :boolean();
}

function SQActor:__init()
	self.name = ''
	self.activeState = false
	self.autoStart = true
end

function SQActor:onStart( ent )
	SQActor.__super.onStart( self, ent )
	if self.autoStart then
		self:startScript()
	end
end

function SQActor:onAttach( ent )
	SQActor.__super.onAttach( self, ent )
	local scene = ent:getScene()
	local actorRegistry = scene:getUserObject( 'SQActors' )
	if not actorRegistry then
		actorRegistry = {}
		scene:setUserObject( 'SQActors', actorRegistry )
	end
	actorRegistry[ self ] = true
	self:loadScript()
end

function SQActor:onDetach( ent )
	SQActor.__super.onDetach( self, ent )
	local scene = ent:getScene()
	local actorRegistry = scene:getUserObject( 'SQActors' )
	actorRegistry[ self ] = nil
end

function SQActor:findActorByName( name )
	local scene = self:getScene()
	local actorRegistry = scene:getUserObject( 'SQActors' )
	for actor in pairs( actorRegistry ) do
		if actor.name == name then return actor end
	end
	return nil
end

function SQActor:onMsg( msg, data, source )
	local state = self.activeState
	if not state then return end
	state:onMsg( msg, data, source )
end

function SQActor:getScript()
	return self.scriptPath
end

function SQActor:setScript( path )
	self.scriptPath = path
	self.script = false
	self:loadScript()
end

function SQActor:loadScript()
	if not self._entity then return end
	self.activeState = SQState()
	local script = loadAsset( self.scriptPath )
	self.script = script
end

function SQActor:startScript()
	if not self.script then return end
	self.activeState:setEnv( 'actor',  self )
	self.activeState:setEnv( 'entity', self:getEntity() )
	self.activeState:loadScript( self.script )
	self:findAndStopCoroutine( 'actionExecution' )
	self:addCoroutine( 'actionExecution' )
end

function SQActor:stopScript()
	if not self.activeState then return end
	self.activeState:stop()
	self:findAndStopCoroutine( 'actionExecution' )
end

function SQActor:actionExecution()
	local state = self.activeState
	if not state then return end
	local dt = 0
	while true do
		state:update( dt )
		dt = coroutine.yield()
	end
end

function SQActor:findRoutineContext( name )
	if not self.activeState then return end
	return self.activeState:findRoutineContext( name )
end

function SQActor:stopRoutine( name )
	if not self.activeState then return end
	return self.activeState:stopRoutine( name )
end

function SQActor:startRoutine( name )
	if not self.activeState then return end
	return self.activeState:startRoutine( name )
end

function SQActor:restartRoutine( name )
	if not self.activeState then return end
	return self.activeState:restartRoutine( name )
end

function SQActor:isRoutineRunning( name )
	if not self.activeState then return end
	return self.activeState:isRoutineRunning( name )
end

function SQActor:startAllRoutines()
	if not self.activeState then return end
	return self.activeState:startAllRoutines()
end

function SQActor:_findContextEntity( id )
	for key, provider in pairs( SQContextProviders ) do
		local ent = provider:get( self, id )
		if ent then return ent end
	end
	return nil
end

function SQActor:getContextEntity( contextId )
	if not contextId or contextId == 'self' then
		return self:getEntity()
	end
	return self:_findContextEntity( contextId )
end

function SQActor:getContextEntities( contexts )
	local result = {}
	local n = #contexts
	if n == 0 then
		return { self:getEntity() }
	end
	for i, id in ipairs( contexts ) do
		local ent
		if id == 'self' then
			ent = self:getEntity()
		else
			ent = self:_findContextEntity( id )
		end
		if ent then
			table.insert( result, ent )
		end
	end
	return result
end

--------------------------------------------------------------------


--------------------------------------------------------------------
mock.registerComponent( 'SQActor', SQActor )
