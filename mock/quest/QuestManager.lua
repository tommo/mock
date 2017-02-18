module 'mock'

--------------------------------------------------------------------
local _questManger
function getQuestManger()
	return _questManger
end

--------------------------------------------------------------------
CLASS: QuestSession ()
	:MODEL{}

function QuestSession:__init()
	self.name = false
	self.comment = ''
	self.states  = {}
	self.default = false
end

function QuestSession:setName( name )
	self.name = name
	_questManger:updateSessionMap()
end

function QuestSession:getState( name )
	for i, state in ipairs( self.states ) do
		if state.name == name then return state end
	end
end

function QuestSession:addState( schemePath )
	if not schemePath then return false end
	local scheme = mock.loadAsset( schemePath)
	local state = QuestState( scheme )
	table.insert( self.states, state )
	return state
end

function QuestSession:getNodes( name )
	local result = {}
	for i, state in ipairs( self.states ) do
		local scheme = state:getScheme()
		if scheme then
			local node = scheme:getNode( name )
			if node then table.insert( result, { state, node } ) end
		end
	end
	return result
end

function QuestSession:findNodes( pattern )
	local result = {}
	for i, state in ipairs( self.states ) do
		local scheme = state:getScheme()
		if scheme then
			local node = scheme:findNode( pattern ) --TODO: find all
			if node then table.insert( result, { state, node } ) end
		end
	end
	return result
end

function QuestSession:checkQuestState( name, checkState )
	local found = self:getNodes( name )
	if not next( found ) then
		_warn( 'no quest node found', name )
		return false
	end
	for i, entry in ipairs( found ) do
		local state, node = unpack( entry )
		local nodeState = state:getNodeState( node.fullname )
		if nodeState ~= checkState then return false end
	end
	return true
end

function QuestSession:update( dt )
	for i, state in ipairs( self.states ) do
		state:update()
	end
end

function QuestSession:reset()
	for i, state in ipairs( self.states ) do
		state:reset()
	end
end

function QuestSession:saveState()
	local stateData = {}
	for i, state in ipairs( self.states ) do
		stateData[ i ] = {
			name   = state.name,
			scheme = state.scheme.path,
			state  = state:save(),
		}
	end
	return {
		states = stateData
	}
end

function QuestSession:loadState( data )
	--validate
	for i, stateData in ipairs( data[ 'states' ] or {} ) do
		local name = stateData[ 'name' ]
		local state = self:getState( name )
		if not state then
			_error( 'quest state not exists', name )
			return false
		end
		if stateData[ 'scheme' ] ~= state.scheme.path then
			_error( 'quest state scheme mismatched', name, stateData[ 'scheme' ] )
			return false
		end
	end

	local hasError = false
	for i, stateData in ipairs( data[ 'states' ] or {} ) do
		local name = stateData[ 'name' ]
		local state = self:getState( name )
		if not state:load( stateData[ 'state' ] ) then hasError = true end
	end

	return not hasError
end

function QuestSession:saveConfig()
	local stateConfig = {}
	for i, state in ipairs( self.states ) do
		local name = state.name
		stateConfig[ i ] = {
			name = state.name,
			scheme = state.scheme and state.scheme.path
		}
	end
	return {
		name    = self.name,
		comment = self.comment,
		states  = stateConfig,
		default = self.default,
	}
end

function QuestSession:loadConfig( data )
	local states = {}
	self.name = data[ 'name' ]
	self.comment = data[ 'comment' ]
	for i, stateConfig in ipairs( data[ 'states' ] ) do
		local schemePath = stateConfig[ 'scheme' ]
		local scheme = mock.loadAsset( schemePath )
		if not scheme then
			_error( 'failed loading quest scheme:', schemePath )
			return false
		end
		local state = QuestState( scheme )
		state.name = stateConfig[ 'name' ]
		table.insert( states, state )
	end
	self.states = states
	self.default = data[ 'default' ] or false
end


--------------------------------------------------------------------
CLASS: QuestManager ( GlobalManager )
	:MODEL{}

function QuestManager:__init()
	self.sessions = {}
	self.sessionMap = {}
	self.pendingUpdate = true
end

function QuestManager:getKey()
	return 'QuestManager'
end

function QuestManager:updateSessionMap()
	local map = {}
	for i, session in ipairs( self.sessions ) do
		local name = session.name
		if name then
			if map[ session.name ] then
				_warn( 'duplicated quest session name', name )
			else
				map[ session.name ] = session
			end
		end
	end
	self.sessionMap = map
end

function QuestManager:scheduleUpdate()
	self.pendingUpdate = true
end

function QuestManager:postInit( game )
	for i, provider in pairs( getQuestContextProviders() ) do
		provider:init()
	end
end

function QuestManager:onUpdate( game, dt )
	if not self.pendingUpdate then return end
	self.pendingUpdate = false
	for _, session in ipairs( self.sessions ) do
		session:update( dt )
	end
end

function QuestManager:getDefaultSession()
	return self.defaultSession
end

function QuestManager:getSession( name )
	return self.sessionMap[ name ]
end

function QuestManager:addSession()
	local session = QuestSession()
	table.insert( self.sessions, session )
	return session
end

function QuestManager:saveConfig()
	local data = {}
	local sessionDatas = {}
	for i, session in ipairs( self.sessions ) do
		sessionDatas[ i ] = session:saveConfig()
	end
	return {
		sessions = sessionDatas
	}
end

function QuestManager:loadConfig( data )
	local sessions = {}
	local defaultSession = false
	for i, sessionData in ipairs( data[ 'sessions' ] or {} ) do
		local session = QuestSession()
		session:loadConfig( sessionData )
		sessions[ i ] = session
		if session.default then
			defaultSession = session
		end
	end
	if not defaultSession then
		local session1 = sessions[ 1 ]
		if session1 then
			session1.default = true
			defaultSession = session1
		end
	end
	self.defaultSession = defaultSession
	self:updateSessionMap()
	self.sessions = sessions
end

--------------------------------------------------------------------
-- tool function
--------------------------------------------------------------------
function isQuestActive ( name )
	local session = getQuestManger():getDefaultSession()
	return session and session:checkQuestState( name, 'active' )
end

function isQuestFinished ( name )
	local session = getQuestManger():getDefaultSession()
	return session and session:checkQuestState( name, 'finished' )
end

function isQuestNotPlayed ( name )
	local session = getQuestManger():getDefaultSession()
	return session and session:checkQuestState( name, nil )
end

function isQuestPlayed ( name )
	local session = getQuestManger():getDefaultSession()
	return session and ( not session:checkQuestState( name, nil ) )
end


--------------------------------------------------------------------
_questManger = QuestManager()
