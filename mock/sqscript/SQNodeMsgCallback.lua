module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeMsgCallback ( SQNodeGroup )
	:MODEL{
		Field 'msg' :string()
	}

function SQNodeMsgCallback:__init()
	self.msg = false
end

function SQNodeMsgCallback:isExecutable()
	return false
end

function SQNodeMsgCallback:load( data )
	local args = data.args
	self.msg = args[1] or false
end

function SQNodeMsgCallback:build( buildContext )
	local routine = self:getRoutine()
	local msg = self.msg
	if isNonEmptyString( msg ) then 
		return routine:addMsgCallback( self.msg, self )
	end
end

function SQNodeMsgCallback:enter( state, env )
end

function SQNodeMsgCallback:exit( state, env )
	return 'end'
end

function SQNodeMsgCallback:getRichText()
	return string.format( '<cmd>SIG</cmd> <signal>%s</signal>', self.msg )
end


--------------------------------------------------------------------
registerSQNode( 'on',    SQNodeMsgCallback )
