module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeQuest ( SQNode )
	:MODEL{
}

function SQNodeQuest:__init()
	self.cmd = false
	self.target = false
end

function SQNodeQuest:load( data )
	local cmd = data.args[ 1 ]
	self.cmd = cmd
	self.target = data.args[ 2 ] or false
	if cmd == 'start' then
	elseif cmd == 'finish' then
	elseif cmd == 'abort' then
	elseif cmd == 'reset' then
	else
		self:_error( 'invalid cmd', tostring( cmd ) )
		return false
	end
	if not self.target then
		self:_error( 'no quest node specified' )
		return false
	end
	return true
end

function SQNodeQuest:enter( state, env )
	local cmd = self.cmd
	local mgr = getQuestManger()
	local session = mgr:getDefaultSession()
	if not session then
		self:_warn( 'no default quest session' )
		return
	end
	if not self.target then return true end
	local entries = session:getNodes( self.target )
	if not next( entries ) then
		self:_warn( 'no node found in quest session', self.target )
		return false
	end
	if cmd == 'finish' then
		for i, entry in ipairs( entries ) do
			local questState, node = unpack( entry )
			local nodeState = questState:getNodeState( node.fullname )
			if nodeState ~= 'active' then
				self:_warn( 'quest node is not active' )
			end
			node:finish( questState )
			mgr:scheduleUpdate()
		end
	elseif cmd == 'abort' then
		for i, entry in ipairs( entries ) do
			local questState, node = unpack( entry )
			local nodeState = questState:getNodeState( node.fullname )
			if nodeState ~= 'active' then
				self:_warn( 'quest node is not active' )
			end
			node:abort( questState )
			mgr:scheduleUpdate()
		end
	elseif cmd == 'reset' then
		for i, entry in ipairs( entries ) do
			local questState, node = unpack( entry )
			local nodeState = questState:getNodeState( node.fullname )
			if not nodeState then
				self:_warn( 'quest node is not started yet' )
			end
			node:reset( questState )
			mgr:scheduleUpdate()
		end
	elseif cmd == 'start' then
		for i, entry in ipairs( entries ) do
			local questState, node = unpack( entry )
			local nodeState = questState:getNodeState( node.fullname )
			if nodeState then
				self:_warn( 'quest node is started or stopped already' )
			end
			node:start( questState )
			mgr:scheduleUpdate()
		end
	end
end


registerSQNode( 'quest', SQNodeQuest )
