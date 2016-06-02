module 'mock'
--------------------------------------------------------------------
CLASS: SQNodeIf ( SQNodeGroup )
	:MODEL{}

function SQNodeIf:__init()
	self.expr = false
end

function SQNodeIf:load( data )
	self.expr = data.args[ 1 ]
	local valueFunc, err   = loadEvalScriptWithEnv( self.expr )
	if not valueFunc then
		_warn( 'failed compiling condition expr:', err )
		self.valueFunc = false
	else
		self.valueFunc = valueFunc
	end
end

local setfenv = setfenv
function SQNodeIf:checkCondition( state, env )
	local func = self.valueFunc
	if not func then return false end

	local ok, result = func( state:getEvalEnv() )
	if ok then return result end
	
	return false
end

function SQNodeIf:enter( state, env )
	local result = self:checkCondition( state, env )
	env[ 'result' ] = result
	if not result then return false end
end

function SQNodeIf:getIcon()
	return 'sq_node_if'
end


--------------------------------------------------------------------
CLASS: SQNodeElseIf ( SQNodeIf )

function SQNodeElseIf:__init()
	self.parentIfNode = false
end

function SQNodeElseIf:build()
	local prev = self:getPrevSibling()
	if prev:isInstance( SQNodeElseIf ) then
		self.parentIfNode = prev.parentIfNode
	elseif prev:isInstance( SQNodeIf ) then
		self.parentIfNode = prev
	end
end

function SQNodeElseIf:enter( state, env )
	local parentEnv = state:getNodeEnvTable( self.parentIfNode )
	if parentEnv[ 'result' ] then
		return false
	end
	local result = self:checkCondition( state, env )
	parentEnv[ 'result' ] = result
	if not result then return false end
end


--------------------------------------------------------------------
CLASS: SQNodeElse ( SQNodeGroup )

function SQNodeElse:__init()
	self.parentIfNode = false
end

function SQNodeElse:build()
	local prev = self:getPrevSibling()
	if prev:isInstance( SQNodeElseIf ) then
		self.parentIfNode = prev.parentIfNode
	elseif prev:isInstance( SQNodeIf ) then
		self.parentIfNode = prev
	end
end

function SQNodeElse:enter( state, env )
	local parentEnv = state:getNodeEnvTable( self.parentIfNode )
	if parentEnv[ 'result' ] then
		return false
	end
end

-------------------------------------------------------------------

registerSQNode( 'if', SQNodeIf )
registerSQNode( 'elseif', SQNodeElseIf )
registerSQNode( 'else', SQNodeElse )
