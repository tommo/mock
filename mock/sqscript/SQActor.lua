module 'mock'
--------------------------------------------------------------------
CLASS: SQActor ( Behaviour )
	:MODEL{
		Field 'script' :asset( 'sq_script' ) :getset( 'Script' );
		Field 'autoStart' :boolean();
}

function SQActor:__init()
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
	self:loadScript()
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
		if not state:isRunning() then break end
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


--------------------------------------------------------------------
mock.registerComponent( 'SQActor', SQActor )
