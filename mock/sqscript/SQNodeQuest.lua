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
	if not self.target then return true end
	local cmd = self.cmd
	local mgr = getQuestManger()
	local session, node = mgr:getQuestNode( self.target )
	if not ( node and session ) then
		self:_warn( 'no node/session found in quest session', self.target )
		return false
	end
	local questState = session:getState()
	local nodeState = questState:getNodeState( node.fullname )
	if cmd == 'finish' then
		if nodeState ~= 'active' then
			self:_warn( 'quest node is not active' )
		end
		node:finish( questState )

	elseif cmd == 'abort' then
		if nodeState ~= 'active' then
			self:_warn( 'quest node is not active' )
		end
		node:abort( questState )

	elseif cmd == 'reset' then
		if not nodeState then
			self:_warn( 'quest node is not started yet' )
		end
		node:reset( questState )

	elseif cmd == 'start' then
		if nodeState then
			self:_warn( 'quest node is started or stopped already' )
		end
		node:start( questState )

	else --unknown command
		self:_warn( 'unknown quest cmd', cmd )
		return false

	end
	
	mgr:forceUpdate()

end


registerSQNode( 'quest', SQNodeQuest )
