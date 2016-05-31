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

function SQNodeMsg:load( data )
	local args = data.args
	self.msg = args[1] or false
	self.data = args[2] or ''
end

function SQNodeMsg:enter( state, env )
	if not self.msg or self.msg == '' then return false end
	local targets = self:getContextEntities( state )
	for i, target in ipairs( targets ) do
		target:tell( self.msg, self.data )
	end
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

function SQNodeWaitMsg:enter( state, env )
	local entity = state:getEnv( 'entity' )
	if not entity then return false end
	local msgListener = function( msg, data )
		return self:onMsg( state, env, msg, data )
	end
	env.msgListener = msgListener
	entity:addMsgListener( msgListener )
end

function SQNodeWaitMsg:step( state, env )
	if env.received then
		local entity = state:getEnv( 'entity' )
		entity:removeMsgListener( env.msgListener )
		return true
	end
end

function SQNodeWaitMsg:onMsg( state, env, msg, data )
	if msg == self.msg then
		env.received = true
	end
end

function SQNodeWaitMsg:getRichText()
	return string.format( '<cmd>WAIT_MSG</cmd> <data>%s</data>', self.msg )
end

--------------------------------------------------------------------
registerSQNode( 'tell', SQNodeMsg   )
registerSQNode( 'wait_msg', SQNodeWaitMsg )
