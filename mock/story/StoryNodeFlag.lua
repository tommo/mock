module 'mock'


local function makeFlagExpr( node, text, chunkName )
	--'$/$$' to name space
	text = text:gsub( '%$%$', '_GLOBAL_.' )
	text = text:gsub( '%$',  '_SCOPE_.'  )
	local src = string.format( 'return (%s)', text )
	local evalFunc, err = loadstring( src, chunkName )
	if not evalFunc then
		print( src )
		print( err )
		error( 'failed parsing Flag expression' )
	end

	local builtinSymbolsMT = {}
	local builtinSymbols = setmetatable(
		{
			_GLOBAL_ = {},
			_SCOPE_  = {}
		}, builtinSymbolsMT )

	setfenv( evalFunc, builtinSymbols )

	local exprFunc = function( state )
		local l, s, g = state:getFlagAccessors( node )
		builtinSymbolsMT.__index = assert( l )
		builtinSymbols._SCOPE_   = assert( s )
		builtinSymbols._GLOBAL_  = assert( g )
		return evalFunc()
	end

	return exprFunc
end

--------------------------------------------------------------------
CLASS: StoryNodeFlag ( StoryNode )
	:MODEL{}

function StoryNodeFlag:__init()
	self.exprFunc = false
end

function StoryNodeFlag:onStateUpdate( state )
	local succ, flag = pcall( self.exprFunc, state )
	if succ and flag then
		if self.hasYesRoute then return true end
	else
		if self.hasNotRoute then return false end
	end
	return 'running' --block until flag changed
end

function StoryNodeFlag:onLoad( nodeData )
	self.exprFunc = makeFlagExpr( self, self.text )

	local hasNotRoute, hasYesRoute = false, false
	for i, r in pairs( self.routesOut ) do
		if r.type == 'NOT' then
			hasNotRoute = true
		else
			hasYesRoute = true
		end
	end
	self.hasNotRoute = hasNotRoute
	self.hasYesRoute = hasYesRoute
end


--------------------------------------------------------------------
local function parseSingleFlagSetter( node, text, value )	
	--match single flag
	local prefix, flagName = text:match( '^%s*(%$?%$?)([%w_]+)%s*$' )
	if not prefix then return false end
	local scope
	if prefix == '$$' then		
		node.setterFunc = function( state )
			local dict
			dict = state:getGlobalFlagDict()
			dict:set( flagName, value )
		end	
	elseif prefix == '$' then
		node.setterFunc = function( state )
			local dict
			dict = state:getScopeFlagDict( node )
			dict:set( flagName, value )
		end
	else		
		node.setterFunc = function( state )
			local dict
			dict = state:getLocalFlagDict( node )
			dict:set( flagName, value )
		end
	end
	return true
end


local function parseSimpleFlagSetter( node, text )
	-- flagname =/+=/-=/*=/ /= / constant
	local prefix, flagName, op, expr
		= text:match( '^%s*(%$?%$?)([%w_]+)%s*([&|%+%-%*/=]*)%s*(.*)$' )
	if not prefix then return false end
	local scope = 'local'
	if prefix == '$$' then		
		scope = 'global'
	elseif prefix == '$' then
		scope = 'scope'
	end

	local exprFunc = makeFlagExpr( node, expr )
	local setterFunc
	if op == '+=' then
		setterFunc = function( state )
			local dict = state:getFlagDict( scope, node )
			local value0 = tonumber( dict:get( flagName ) ) or 0
			local value = tonumber( exprFunc( state ) ) or 0
			return dict:set( flagName, value0 + value )
		end
	elseif op == '-=' then
		setterFunc = function( state )
			local dict = state:getFlagDict( scope, node )
			local value0 = tonumber( dict:get( flagName ) ) or 0
			local value = tonumber( exprFunc( state ) ) or 0
			return dict:set( flagName, value0 - value )
		end
	elseif op == '*=' then
		setterFunc = function( state )
			local dict = state:getFlagDict( scope, node )
			local value0 = tonumber( dict:get( flagName ) ) or 0
			local value = tonumber( exprFunc( state ) ) or 0
			return dict:set( flagName, value0 * value )
		end
	elseif op == '/=' then
		setterFunc = function( state )
			local dict = state:getFlagDict( scope, node )
			local value0 = tonumber( dict:get( flagName ) ) or 0
			local value = tonumber( exprFunc( state ) ) or 1
			return dict:set( flagName, value0 / value )
		end
	elseif op == '&=' then
		setterFunc = function( state )
			local dict = state:getFlagDict( scope, node )
			local value0 = dict:get( flagName )
			local value = exprFunc( state )
			return dict:set( flagName, value0 and value )
		end
	elseif op == '|=' then
		setterFunc = function( state )
			local dict = state:getFlagDict( scope, node )
			local value0 = dict:get( flagName )
			local value = exprFunc( state )
			return dict:set( flagName, value0 or value )
		end
	elseif op == '=' then
		setterFunc = function( state )
			local dict = state:getFlagDict( scope, node )
			local value = exprFunc( state )
			return dict:set( flagName, value )
		end
	else
		error( 'invalid flag operation:'..op )
		return false
	end
	node.setterFunc = setterFunc
	return true
end


local function parserFlagSetter( node, text )
	if parseSingleFlagSetter( node, text, true ) then return true end	
	if parseSimpleFlagSetter( node, text ) then return true end	
	print( node.id, text )
	error( 'invalid flag setter synatx' )
	return false
end

--------------------------------------------------------------------
CLASS: StoryNodeFlagSet ( StoryNode )
	:MODEL{}

function StoryNodeFlagSet:__init()
	self.setterFunc = false
end

function StoryNodeFlagSet:onStateEnter( state, prevNode, prevResult )
	self.setterFunc( state )
end

function StoryNodeFlagSet:onLoad( nodeData )
	parserFlagSetter( self, self.text )
end


--------------------------------------------------------------------
CLASS: StoryNodeFlagRemove ( StoryNode )
	:MODEL{}

function StoryNodeFlagRemove:__init()
	self.setterFunc = false
end

function StoryNodeFlagRemove:onStateEnter( state, prevNode, prevResult )
	self.setterFunc( state )
end

function StoryNodeFlagRemove:onLoad( nodeData )
	if parseSingleFlagSetter( self, self.text, false ) then return true end
	print( self.id, self.text )
	error( 'invalid flag remover synatx' )
end

registerStoryNodeType( 'FLAG', StoryNodeFlag  )
registerStoryNodeType( 'FLAG_SET', StoryNodeFlagSet  )
registerStoryNodeType( 'FLAG_REMOVE', StoryNodeFlagRemove  )

--------------------------------------------------------------------
CLASS: StoryNodeAssert ( StoryNodeFlag )
	:MODEL{}

function StoryNodeAssert:onStateUpdate()
	local succ, flag = pcall( self.exprFunc, state )
	if succ and flag then return 'ok' end
	_error( 'ERROR:Story Flag Assert Failed.', self.text )
	return 'stop'
end


registerStoryNodeType( 'ASSERT', StoryNodeAssert  )
