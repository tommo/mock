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
	return true
end

function SQNodeMsgCallback:load( data )
	local args = data.args
	self.msg = args[1] or false
end

function SQNodeMsgCallback:build( buildContext )
end

function SQNodeMsgCallback:enter( state, env )
	local msg = self.msg
	if isNonEmptyString( msg ) then 
		state:registerMsgCallback( self.msg, self )
	end
	return false
end

function SQNodeMsgCallback:exit( state, env )
	return 'end'
end

function SQNodeMsgCallback:getRichText()
	return string.format( '<cmd>SIG</cmd> <signal>%s</signal>', self.msg )
end


--------------------------------------------------------------------
registerSQNode( 'on',    SQNodeMsgCallback )
