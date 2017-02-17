module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeAssert ( SQNode )
	:MODEL{}

function SQNodeAssert:__init()
	self.expr = false
end

function SQNodeAssert:load( data )
	self.expr = data.args[ 1 ]
	local valueFunc, err   = loadEvalScriptWithEnv( self.expr )
	if not valueFunc then
		self:_warn( 'failed compiling condition expr:', err )
		self.valueFunc = false
	else
		self.valueFunc = valueFunc
	end
end

local setfenv = setfenv
function SQNodeAssert:checkCondition( state, env )
	local func = self.valueFunc
	if not func then return false end

	local ok, result = func( state:getEvalEnv() )
	if ok then return result end
	
	return false
end

function SQNodeAssert:enter( state, env )
	local result = self:checkCondition( state, env )
	if not result then
		self:_error( 'Assert Failed', self.expr )
		state:stop()
		return false
	end		
end

function SQNodeAssert:getIcon()
	return 'sq_node_assert'
end
