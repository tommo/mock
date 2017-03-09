module 'mock'
--------------------------------------------------------------------
--Node State:
-- *nil  *active *finished *abort
--Command:
-- *ABORT *AND *RESET
--Connection Type:
-- *move *spawn
--------------------------------------------------------------------

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
	--build condition expr
	self.condFunc = false
	if cond then
		local valueFunc, err   = loadEvalScriptWithEnv( cond )
		if not valueFunc then
			_warn( 'failed compiling quest condition:', err, from.fullname, '->', to.fullname )
		else
			self.condFunc = valueFunc
		end
	end

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
	local func = self.condFunc
	if not func then return false end --failed compiling
	local ok, result = func( questState:getEvalEnv() )
	if ok then return result end
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
		local nodeFrom = conn.from
		local ns = questState:getNodeState( nodeFrom.fullname, 'includeChange' )
		local ctype = conn.type
		if ctype == 'spawn' then
			if ns ~= 'active' and ns ~= 'finished' then result = false break end
		else
			if ns ~= 'finished' then result = false	break	end
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
	self.root.name     = '@root'
	self.root.fullname = '@root'
	self.nodes = {}
	self.nodeByName  = {}
	self.connections = {}
	self.nodeByName[ '@root' ] = self.root
	self.path = false
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
local function QuestSchemeLoader( node )
	local defFile = node:getObjectFile( 'def' )
	local data = loadAssetDataTable( defFile )
	local scheme = QuestScheme()
	scheme.path = node:getPath()
	scheme:load( data )
	return scheme
end

registerAssetLoader( 'quest_scheme', QuestSchemeLoader )
