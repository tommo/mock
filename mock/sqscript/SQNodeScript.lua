module 'mock'

local defaultSQScript = [[
-- SQNode script
-- callback param:
-- @state mock.SQContext
-- @env environment table for current SQNode

--Callback on entering this node
function enter( state, env )
end

--Callback on each step updating this node
--function step( state, env, dt )
--	return true
--end

--Callback on exiting this node
--function exit( state, env )
--end

]]


local scriptHeader = [[
]]

local scriptTail = [[
]]


CLASS: SQNodeScriptLua ( SQNode )
	:MODEL{
		Field 'summary' :string();
		Field 'script' :string() :widget('codebox');
}

function SQNodeScriptLua:__init()
	self.script = defaultSQScript
	self.summary = 'Script Name'
	self.callbackEnter = false
	self.callbackExit  = false
	self.callbackStep  = false
end

function SQNodeScriptLua:getIcon()
	return 'sq_node_script_lua'
end

function SQNodeScriptLua:getRichText()
	return string.format(
			'<cmd>SCRIPT</cmd> <string>%s</string>',
			self.summary
		)
end

function SQNodeScriptLua:build()
	self.delegate = false
	local finalScript = scriptHeader .. self.script .. scriptTail
	local loader, err = loadstring( finalScript, 'sqnode-script' )
	if not loader then return _error( err ) end
	local delegate = setmetatable( {}, { __index = _G } )
	setfenv( loader, delegate )
	
	local errMsg, tracebackMsg
	local function _onError( msg )
		errMsg = msg
		tracebackMsg = debug.traceback(2)
	end
	local succ = xpcall( function() loader() end, _onError )
	if succ then
		self.delegate = delegate
	else
		return _error( 'failed loading SQNode script' )
	end
	self.callbackEnter = delegate.enter
	self.callbackExit  = delegate.exit
	self.callbackStep  = delegate.step
end

function SQNodeScriptLua:enter( state, env )
	local enter = self.callbackEnter
	if enter then return enter( state, env ) end
end

function SQNodeScriptLua:exit( state, env )
	local exit = self.callbackExit
	if exit then return exit( state, env ) end
end

function SQNodeScriptLua:step( state, env, dt )
	local step = self.callbackStep
	if step then
		return step( state, env, dt )
	else
		return true
	end
end

-------------------------------------------------------------------
registerSQNode( 'script_lua',      SQNodeScriptLua )
