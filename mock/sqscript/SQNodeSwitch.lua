module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeSwitch ( SQNodeGroup )
	:MODEL{}

function SQNodeSwitch:__init()
	self.expr = false
end

function SQNodeSwitch:load( data )
	self.expr = data.args[ 1 ]
	local valueFunc, err = loadEvalScriptWithEnv( self.expr )
	if not valueFunc then
		self:_warn( 'failed compiling variable expr:', err )
		self.valueFunc = false
	else
		self.valueFunc = valueFunc
	end
end

function SQNodeSwitch:enter( state, env )
	if not self.valueFunc then return false end
	local ok, result = self.valueFunc( state:getEvalEnv() )
	if not ok then return false end
	env[ 'result' ] = result
	env[ 'accepted' ] = false
end

function SQNodeSwitch:getIcon()
	return 'sq_node_if'
end


--------------------------------------------------------------------
CLASS: SQNodeSwitchCase ( SQNodeGroup )

function SQNodeSwitchCase:__init()
	self.parentSwitchNode = false
	self.checkFunc = false
	self.valueFunc = false
end

function SQNodeSwitchCase:load( data )
	self.expr = data.args[ 1 ]
	local valueFunc, err = loadEvalScriptWithEnv( self.expr )
	if not valueFunc then
		self:_warn( 'failed compiling variable expr:', err )
		self.valueFunc = false
	else
		self.valueFunc = valueFunc
	end
end

function SQNodeSwitchCase:build()
	local parent = self.parentNode
	if parent:isInstance( SQNodeSwitch ) then
		self.parentSwitchNode = parent
	else
		self.parentSwitchNode = false
	end
end

function SQNodeSwitchCase:enter( state, env )
	local switchNode = self.parentSwitchNode
	if not switchNode then return false end

	local parentEnv = state:getNodeEnvTable( switchNode )
	if parentEnv[ 'accepted' ] then return false end

	if not self.valueFunc then return false end
	local ok, result = self.valueFunc( state:getEvalEnv() )
	if not ok then return false end

	local parentValue = parentEnv[ 'result' ]
	if parentValue == result then
		parentEnv[ 'accepted' ] = true
		return true
	else
		return false
	end
end



--------------------------------------------------------------------
CLASS: SQNodeSwitchDefault ( SQNodeGroup )

function SQNodeSwitchDefault:__init()
	self.parentSwitchNode = false
end

function SQNodeSwitchDefault:build()
	local parent = self.parentNode
	if parent:isInstance( SQNodeSwitch ) then
		self.parentSwitchNode = parent
	else
		self.parentSwitchNode = false
	end
end

function SQNodeSwitchDefault:enter( state, env )
	local switchNode = self.parentSwitchNode
	if not switchNode then return false end

	local parentEnv = state:getNodeEnvTable( switchNode )
	if parentEnv[ 'accepted' ] then return false end

	parentEnv[ 'accepted' ] = true
	return true

end

-------------------------------------------------------------------

registerSQNode( 'switch', SQNodeSwitch )
registerSQNode( 'case', SQNodeSwitchCase )
registerSQNode( 'default', SQNodeSwitchDefault )
