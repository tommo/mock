module 'mock'


--------------------------------------------------------------------
local _contextProviders = {}
function getQuestContextProviders()
	return _contextProviders
end

function registerQuestContextProvider( provider, prepend )
	if prepend ~= false then
		table.insert( _contextProviders, 1, provider )
	else
		table.insert( _contextProviders, provider )
	end
end

--------------------------------------------------------------------
CLASS: QuestContextProvider ()
	:MODEL{}

function QuestContextProvider:__init()
	self.changed = false
end

function QuestContextProvider:init()
end

function QuestContextProvider:getEnvVar( key )
	return false
end

--------------------------------------------------------------------
CLASS: QuestState ()
	:MODEL{}

function QuestState:__init( scheme, ... )
	self.nodeStates   = {}
	self.activeNodes  = {}
	self.changedNodes = {}
	self.changed = false
	self.started = false
	self.running = true
	self.schemes = { scheme, ... }
	self.name    = ''
	self.evalEnv = false
	self.session = false
end

function QuestState:setName( name )
	self.name = name
end

function QuestState:getName()
	return self.name
end

function QuestState:getEnvVar( key )
	for i, provider in ipairs( _contextProviders ) do
		local value = provider:getEnvVar( key )
		if value ~= nil then return value end
	end
	return nil
end

function QuestState:reset()
	self.nodeStates = {}
	self.activeNodes = {}
	self.changedNodes = {}
	self.started = false
end

function QuestState:start()
	if self.started then return end
	self.started = true
	--find entry node
	for i, scheme in ipairs( self.schemes ) do
		local entryNode = scheme:getRoot():getChild( 'start' )
		if entryNode then
			if self:getNodeState( entryNode.fullname ) then return false end
			entryNode:start( self )
			self.changed = true
		else
			_warn( 'no start node in scheme', tostring( scheme.path ) )
		end
	end
end

function QuestState:addScheme( scheme )
	table.insert( self.schemes, scheme )
	if self.started then
		--TODO????
	end
end

function QuestState:getSchemes()
	return self.schemes
end

function QuestState:getNodeState( fullname, includeChange ) --use fullname here, ID is not stable
	if includeChange then
		local found, result = false, nil
		for _, entry in ipairs( self.changedNodes ) do
			local node, s = unpack( entry )
			if node.fullname == fullname then
				found = true
				result = s
			end
		end
		if found then return result end
	end
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
	local node = self:getNodeByName( fullname )
	if not node then
		return _error( 'failed to found quest node to change:', fullname )
	end
	local entry = { node, state }
	table.insert( self.changedNodes, entry )
	self.changed = true
end

function QuestState:checkNodeState( fullname, value )
	local found = self:getNode( fullname )
	if not next( found ) then
		_warn( 'no quest node found', fullname )
		return nil
	end
	return self:getNodeState( fullname ) == value
end

function QuestState:getNode( fullname )
	return self:getNodeByName( fullname )
end

function QuestState:getNodeByName( fullname )
	for i, scheme in ipairs( self.schemes ) do
		local node = scheme:getNodeByName( fullname )
		if node then return node end
	end
	return nil
end

function QuestState:findNode( term, ... )
	for i, scheme in ipairs( self.schemes ) do
		local node = scheme:findNode( term, ... )
		if node then return node end
	end
	return nil
end

function QuestState:getEvalEnv()
	if not self.evalEnv then
		local mt = {
			__index = function( t, k )
				return self:getEnvVar( k )
			end
		}
		self.evalEnv = setmetatable( {}, mt )
	end
	return self.evalEnv
end

function QuestState:update()
	if not self.started then
		self:start()
	end
	if not self.running then return end
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
	local changeData = {}
	for i, entry in pairs( self.changedNodes ) do
		local node, newState = unpack( entry )
		changeData[ i ] = { node.fullname, newState }
	end

	return {
		states  = self.nodeStates,
		changes = changeData,
	}
end

function QuestState:load( data )
	local hasError = false

	local activeNodes = {}
	local changedNodes = {}

	local nodeStates = data[ 'states' ]
	for fullname, state in pairs( nodeStates ) do
		local node = self:getNode( fullname )
		if node then
			if state == 'active' then
				activeNodes[ node ] = true
			end
		else
			hasError = true
			_error( 'quest node not found', fullname )
		end
	end

	for i, entry in ipairs( data[ 'changes' ] ) do
		local fullname, newState = unpack( entry )
		local node = self:getNode( fullname )
		if node then
			changedNodes[ i ] = { node, newState }
		else
			hasError = true
			_error( 'quest node not found', fullname )
		end
	end
	self.nodeStates   = nodeStates
	self.activeNodes  = activeNodes
	self.changedNodes = changedNodes
	self.changed = true
	return not hasError
end
