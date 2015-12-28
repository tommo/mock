module 'mock'
--------------------------------------------------------------------
CLASS: SQActor ( Behaviour )
	:MODEL{
		Field 'script' :asset( 'sq_script' ) :getset( 'Script' )
}



function SQActor:__init()
	self.context = false
end

function SQActor:onStart( ent )
	SQActor.__super.onStart( self, ent )
	self:startScript()
end

function SQActor:getScript()
	return self.scriptPath
end

function SQActor:setScript( path )
	self.scriptPath = path
	local script = loadAsset( path )
	self.script = script
end

function SQActor:startScript()
	if not self.script then return end
	self.context = SQContext()
	self.context:setEnv( 'actor', self )
	self.context:loadScript( self.script )
	self:findAndStopCoroutine( 'actionExecution' )
	self:addCoroutine( 'actionExecution' )
end

function SQActor:stopScript()
	if not self.context then return end
	self.context:stop()
	self.context = false
	self:findAndStopCoroutine( 'actionExecution' )
end

function SQActor:actionExecution()
	local context = self.context
	if not context then return end
	local dt = 0
	while true do
		context:update( dt )
		dt = coroutine.yield()
	end
end

--------------------------------------------------------------------
mock.registerComponent( 'SQActor', SQActor )
