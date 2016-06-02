module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeEval ( SQNode )
	:MODEL{
		Field 'script' :string();
	}

function SQNodeEval:__init()
	self.script = ''
	self.scriptFunc = false
end

function SQNodeEval:load( data )
	local args = data.args
	local script = false
	for i, arg in ipairs( data.args ) do
		if not script then
			script = arg
		else
			script = script .. '\n' .. arg
		end
	end
	self.script = script
	local func, err = loadstring( script )
	if not func then
		_warn( 'failed compiling eval function', err )
		self.scriptFunc = false
	else
		self.scriptFunc = func
	end
end

local setfenv = setfenv
function SQNodeEval:enter( state, env )
	local func = self.scriptFunc
	if not func then return false end
	setfenv( func, state:getEvalEnv() )
	pcall( func )
end

function SQNodeEval:getRichText()
	return string.format( '<cmd>EVAL</cmd> <comment>%s</comment>', self.script )
end

--------------------------------------------------------------------
registerSQNode( 'eval', SQNodeEval )
