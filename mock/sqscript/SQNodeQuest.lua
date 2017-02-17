module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeQuest ( SQNode )
	:MODEL{
}

function SQNodeQuest:__init()
	self.cmd = false
end

function SQNodeQuest:load( data )
	local cmd = data.args[ 1 ]
	self.cmd = cmd
	if cmd == 'tell' then
	elseif cmd == 'finish' then
	elseif cmd == 'cancel' then
	end
end

function SQNodeQuest:enter( state, env )
	local cmd = self.cmd
	local path = self.path

	if cmd == 'open' then
		self:onCmdOpen( state, env, path )

	elseif cmd == 'add' then
		self:onCmdAdd( state, env, path )

	elseif cmd == 'reopen' then
		self:onCmdReopen( state, env )

	end
end


registerSQNode( 'quest', SQNodeQuest )
