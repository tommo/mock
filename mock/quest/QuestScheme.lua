module 'mock'

--------------------------------------------------------------------
CLASS: QuestNodeBase ()
	:MODEL{}

function QuestNodeBase:__init()
	self.name = false
	self.fullname = false
	self.scheme = false
	self.parent = false
	self.children    = {}
	self.connectionsOut = {}
	self.connectionsIn  = {}
end

function QuestNodeBase:isCommand()
	return false
end

function QuestNodeBase:getType()
	return 'node'
end

function QuestNodeBase:validate()
	-- local name = node.name
	-- for i, child in ipairs( self.children ) do
	-- 	if child.name == node.name then
	-- 		_warn( 'duplicated QuestNodeBase:', name )
	-- 		return false
	-- 	end
	-- end
	return true
end

function QuestNodeBase:addChild( node )
	table.insert( self.children, node )
	node.parent = self
	node.scheme = self
end

function QuestNodeBase:getScheme()
	return self.scheme
end

function QuestNodeBase:getParent()
	return self.parent
end

function QuestNodeBase:getChildren()
	return self.children
end

function QuestNodeBase:getChild( name )
	for i, child in ipairs( self.children ) do
		if child.name == name then return child end
	end
	return false
end

function QuestNodeBase:getName()
	return self.name
end

function QuestNodeBase:getFullName()
	if not self.parent then return false end--root
	if not self.fullname then
		local base = self.parent:getFullName()
		if base then
			self.fullname = base .. '.' .. self.name
		else
			self.fullname = self.name
		end
	end
	return self.fullname
end

local match = string.match
local gsub  = string.gsub
function QuestNodeBase:findChild( name, deep )
	if deep then
		for i, child in ipairs( self.children ) do
			local found = child:findChild( name )
			if found then return found end
		end
	end
	local suffixPattern = '%.'..gsub( name, '%.', '%%.' )..'$'
	for i, child in ipairs( self.children ) do
		local childName = child.name
		if ( childName == name ) or match( childName, suffixPattern ) then
			return child
		end
	end
	return false
end

function QuestNodeBase:reset( questState, from )
end

function QuestNodeBase:finish( questState, from )
end

function QuestNodeBase:abort( questState, from )
end

function QuestNodeBase:start( questState, from )
end

function QuestNodeBase:update( questState )
end

--------------------------------------------------------------------
CLASS: QuestConnection ()
	:MODEL{}

function QuestConnection:__init( from, to, ctype, cond )
	self.type = ctype --'move' --'spawn', 'abort'
	self.from = from
	self.to = to
	if cond and cond:trim() == '' then cond = false end
	self.cond = cond or false
	table.insert( from.connectionsOut, self )
	table.insert( to.connectionsIn,   self  )
	self._isExitConn = ctype == 'move' and ( not cond )
end

function QuestConnection:isExitConn()
	return self._isExitConn	
end

function QuestConnection:sendSignal( questState, cmd, from )
	local ctype = self.type
	if ctype == 'move' then
		self.from:finish( questState, self )
	end
	if cmd == 'start' then
		self.to:start( questState, self )
	elseif cmd == 'abort' then
		self.to:abort( questState, self )
	elseif cmd == 'reset' then
		self.to:reset( questState, self )
	end
end

function QuestConnection:onSourceFinished( questState, from )
	if not self:isExitConn() then return false end
	self.to:start( questState, self )
end

function QuestConnection:evaluate( questState )
	local cond = self.cond
	if not cond then return true end
	--TODO: eval
	return false
end

--------------------------------------------------------------------
CLASS: QuestNode ( QuestNodeBase )
	:MODEL{}

function QuestNode:getType()
	return 'node'
end

function QuestNode:isCommand()
	return false
end

function QuestNode:reset( questState, from )
	for i, child in ipairs( self.children ) do
		child:reset( questState, from )
	end
	questState:setNodeState( self.fullname, nil )
end

function QuestNode:finish( questState, from )
	for i, child in ipairs( self.children ) do
		child:abort( questState, from )
	end
	questState:setNodeState( self.fullname, 'finished' )
	if self.name == 'stop' then
		if self.parent then
			self.parent:finish( questState )
		end
	end
end

function QuestNode:abort( questState, from )
	for i, child in ipairs( self.children ) do
		child:abort( questState, from )
	end
	local state0 = questState:getNodeState( self.fullname )
	if state0 ~= 'aborted' and state0 ~= 'finished' then
		questState:setNodeState( self.fullname, 'aborted' )
	end
end

function QuestNode:start( questState, from )
	local state0 = questState:getNodeState( self.fullname ) or false
	if state0 then return false end --visited
	if self.name == 'start' or self.name == 'stop' then
		return self:finish( questState, from )
	end
	questState:setNodeState( self.fullname, 'active' )
	local subNode = self:getChild( 'start' )
	if subNode then
		subNode:start( questState, from )
	end
end

function QuestNode:update( questState )
	for i, conn in ipairs( self.connectionsOut ) do
		if not ( conn:isExitConn() ) and conn:evaluate( questState ) then
			conn:sendSignal( questState, 'start', self )
		end
	end
end

--------------------------------------------------------------------
CLASS: QuestNodeCommand ( QuestNodeBase )
function QuestNodeCommand:isCommand()
	return true
end

--------------------------------------------------------------------
CLASS: QuestNodeAnd ( QuestNodeCommand )
	:MODEL{}

function QuestNodeAnd:getType()
	return 'and'
end

function QuestNodeAnd:start( questState, from )
	--check from states
	local result = true
	for i, conn in ipairs( self.connectionsIn ) do
		local node = conn.from
		local ns = node.state
		if not ( ns == 'active' or ns == 'finished' ) then
			result = false
			break
		end
	end
	if not result then return false end
	for i, conn in ipairs( self.connectionsOut ) do
		if conn:evaluate( questState ) then
			conn:sendSignal( questState, 'start', self )
		end
	end
end

--------------------------------------------------------------------
CLASS: QuestNodeAbort ( QuestNodeCommand )
	:MODEL{}

function QuestNodeAbort:getType()
	return 'abort'
end

function QuestNodeAbort:start( questState, from )
	for i, conn in ipairs( self.connectionsOut ) do
		if conn:evaluate( questState ) then
			conn:sendSignal( questState, 'abort', self )
		end
	end
end

--------------------------------------------------------------------
CLASS: QuestNodeReset ( QuestNodeCommand )
	:MODEL{}

function QuestNodeReset:getType()
	return 'reset'
end

function QuestNodeReset:start( questState, from )
	for i, conn in ipairs( self.connectionsOut ) do
		if conn:evaluate( questState ) then
			conn:sendSignal( questState, 'reset', self )
		end
	end
end

--------------------------------------------------------------------
CLASS: QuestScheme ()
	:MODEL{}

function QuestScheme:__init()
	self.root = QuestNode()
	self.root.scheme = self
	self.nodes = {}
	self.nodeByName  = {}
	self.connections = {}
end

function QuestScheme:getRoot()
	return self.root
end

function QuestScheme:_loadNode( parentNode, data )
	local tt = data[ 'type' ]
	local node
	if tt == 'and' then
		node = QuestNodeAnd()
	elseif tt == 'abort' then
		node = QuestNodeAbort()
	elseif tt == 'reset' then
		node = QuestNodeReset()
	else
		node = QuestNode()
	end
	node.id          = data[ 'id' ]
	node.name        = data[ 'name' ]
	node.fullname    = data[ 'fullname' ]
	node.scheme      = self
	if node.fullname then
		self.nodeByName[ node.fullname ] = node
	end
	parentNode:addChild( node )
	self.nodes[ node.id ] = node
	for key, childData in pairs( data[ 'children' ] ) do
		self:_loadNode( node, childData )
	end
	return node
end

function QuestScheme:_loadConnections( data )
	local map = self.nodes
	local connections = {}
	for i, connData in ipairs( data ) do
		local fromId = connData[ 'from' ]
		local toId   = connData[ 'to' ]
		local ctype  = connData[ 'type' ] 
		local cond    = connData[ 'cond' ]
		local from   = map[ fromId ]
		local to     = map[ toId ]
		local fromType = from:getType()
		local toType = to:getType()
		local conn   = QuestConnection( from, to, ctype, cond )
		connections[ conn ] = true
	end
	self.connections = connections
end

function QuestScheme:load( data )
	local root = self.root
	for i, nodeData in ipairs( data[ 'nodes' ] ) do
		self:_loadNode( root, nodeData )
	end
	self:_loadConnections( data[ 'connections' ] )
end

function QuestScheme:getNode( name )
	return self.nodeByName[ name ] or false
end

function QuestScheme:getNodeByName( name )
	return self.nodeByName[ name ] or false
end

function QuestScheme:findNode( name )
	return self.root:findChild( name, true )
end


--------------------------------------------------------------------
--Node State:
-- *false  *start -> *active -> *finish/*abort
--Connection Type:
-- *move *spawn *stop
--------------------------------------------------------------------
--------------------------------------------------------------------
CLASS: QuestVariableProvider ()
	:MODEL{}

function QuestVariableProvider:__init()
	self.changed = false
end

function QuestVariableProvider:getVar( key )
	return false
end

function QuestVariableProvider:peek()
	return self.changed or false
end

function QuestVariableProvider:poll()
	local result = self.changed
	self.changed = false
	return result
end


--------------------------------------------------------------------
CLASS: QuestState ()
	:MODEL{}

function QuestState:__init( scheme )
	self.nodeStates   = {}
	self.activeNodes  = {}
	self.changedNodes = {}
	self.variableProviders = {}
	self.changed = false
	self.running = true
	self.scheme  = scheme
end

function QuestState:addVariableProvider( provider, prepend )
	if prepend then
		table.insert( self.variableProviders, 1, provider )
	else
		table.insert( self.variableProviders, provider )
	end
end

function QuestState:getVar( key )
	for i, provider in ipairs( self.variableProviders ) do
		local value = provider:getVar( key )
		if value ~= nil then return value end
	end
	return nil
end

function QuestState:reset()
	self.nodeStates = {}
	self.activeNodes = {}
	self.changedNodes = {}
	self.changed = true
	--find entry node
	local scheme = self.scheme
	local entryNode = scheme:getRoot():getChild( 'start' )
	if not entryNode then
		_warn( 'no start node in scheme' )
		return false
	end
	entryNode:start( self )
end

function QuestState:getScheme()
	return self.scheme
end

function QuestState:getNodeState( fullname ) --use fullname here, ID is not stable
	return self.nodeStates[ fullname ]
end

function QuestState:setNodeState( target, state )
	local fullname
	if type( target ) == 'string' then
		fullname = target
	else 
		fullname = target.fullname
	end
	local s0 = self:getNodeState( fullname )
	if s0 == state then return false end
	_logf( '%s -> %s', fullname, tostring( state )  )
	local node = self.scheme:getNodeByName( fullname )
	if not node then
		return _error( 'failed to found quest node to change:', fullname )
	end
	local entry = { node, state }
	-- local newstate0 = self.changedNodes[ node ]
	-- if newstate0 ~= nil and newstate0 ~= state then
	-- 	return _warn( 'quest node is already changed', fullname, newstate0, state )
	-- end
	-- self.changedNodes[ node ] = state
	table.insert( self.changedNodes, entry )
	self.changed = true
end

function QuestState:update()
	if not self.running then return end
	local scheme = self.scheme
	local _CYCLE = 0
	while true do
		--apply change
		local changedNodes = table.simplecopy( self.changedNodes )
		self.changedNodes = {}
		self.changed = false
		local newActiveNodes = {}
		local activeNodes = self.activeNodes
		for _, entry in ipairs( changedNodes ) do
			local node, newState = unpack( entry )
			local fullname = node.fullname
			local oldState = self:getNodeState( fullname )
			self.nodeStates[ fullname ] = newState
			if newState == 'finished' then
				for i, conn in ipairs( node.connectionsOut ) do
					conn:onSourceFinished( self )
				end
				activeNodes[ node ] = nil
			elseif newState == 'aborted' or newState == nil then
				activeNodes[ node ] = nil
			elseif newState == 'active' then
				activeNodes[ node ] = true
			else
				_error( 'unknown quest node state', newState )
			end
		end
		for node in pairs( activeNodes ) do
			node:update( self )
		end
		if not self.changed then break end
		_CYCLE = _CYCLE + 1
		if _CYCLE > 100 then
			_error( 'too much quest update cycles! possible endless loop in graph.' )
			self.running = false
			return false
		end
	end
end

function QuestState:save()
	local data = {}
	local changedNames = {}
	local activeNames = {}
	for node in pairs( self.changedNodes ) do
		table.insert( changedNames, node.fullname )
	end
	for node in pairs( self.activeNodes ) do
		table.insert( activeNames, node.fullname )
	end
	data[ 'changed' ] = changedNames
	data[ 'active'  ] = activeNames
	data[ 'states'  ] = self.nodeStates
	return data
end

function QuestState:load( data )
	local changedNodes = {}
	local activeNodes = {}
	local scheme = self.scheme
	local hasError = false
	for i, name in ipairs( data[ 'changed' ] ) do
		local node = scheme:getNodeByName( name )
		if node then
			changedNodes[ node ] = true
		else
			_warn( 'quest node not found while loading:', name )
			hasError = true
		end
	end
	for i, name in ipairs( data[ 'active' ] ) do
		local node = scheme:getNodeByName( name )
		if node then
			activeNodes[ node ] = true
		else
			_warn( 'quest node not found while loading:', name )
			hasError = true
		end
	end
	self.nodeStates   = data[ 'nodeStates' ]
	self.activeNodes  = activeNodes
	self.changedNodes = changedNodes
	return not hasError
end

--------------------------------------------------------------------
local function QuestSchemeLoader( node )
	local defFile = node:getObjectFile( 'def' )
	local data = loadAssetDataTable( defFile )
	local scheme = QuestScheme()
	scheme:load( data )
	return scheme
end

registerAssetLoader( 'quest_scheme', QuestSchemeLoader )
