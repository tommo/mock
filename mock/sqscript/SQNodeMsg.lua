module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeMsg ( SQNode )
	:MODEL{
		Field 'msg'  :string();
		Field 'data' :string();
	}

function SQNodeMsg:__init()
	self.msg  = ''
	self.data = ''
end

function SQNodeMsg:enter( context, env )
	local actor = context:getEnv( 'actor' )
	if not actor then return end
	return actor:tell( self.msg, self.data )
end

function SQNodeMsg:getRichText()
	return string.format( '<cmd>MSG</cmd> <data>%s ( <string>%s</string> )</data>', self.msg, self.data )
end


--------------------------------------------------------------------
CLASS: SQNodeWaitMsg ( SQNode )
	:MODEL{
		Field 'msg' :string()
	}

function SQNodeWaitMsg:__init()
	self.msg = ''
end

function SQNodeWaitMsg:enter( context, env )
	local actor = context:getEnv( 'actor' )
	if not actor then return false end
	local msgListener = function( msg, data )
		return self:onMsg( context, env, msg, data )
	end
	env.msgListener = msgListener
	actor:getEntity():addMsgListener( msgListener )
end

function SQNodeWaitMsg:step( context, env )
	if env.received then
		local actor = context:getEnv( 'actor' )
		actor:getEntity():removeMsgListener( env.msgListener )
		return true
	end
end

function SQNodeWaitMsg:onMsg( context, env, msg, data )
	if msg == self.msg then
		env.received = true
	end
end

function SQNodeWaitMsg:getRichText()
	return string.format( '<cmd>WAIT_MSG</cmd> <data>%s</data>', self.msg )
end

--------------------------------------------------------------------
registerSQNode( 'msg', SQNodeMsg   )
registerSQNode( 'wait_msg', SQNodeWaitMsg )
