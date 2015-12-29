module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeSignal ( SQNode )
	:MODEL{
		Field 'signalId' :string()
	}

function SQNodeSignal:__init()
	self.signalId = ''
end

function SQNodeSignal:enter( context, env )
	context:incSignalCounter( self.signalId )
end

function SQNodeSignal:getRichText()
	return string.format( '<cmd>SIG</cmd> <signal>%s</signal>', self.signalId )
end



--------------------------------------------------------------------
CLASS: SQNodeWaitSignal ( SQNode )
	:MODEL{
		Field 'signalId' :string()
	}

function SQNodeWaitSignal:__init()
	self.signalId = ''
end

function SQNodeWaitSignal:enter( context, env )
	local counter = context:getSignalCounter( self.signalId )
	env.counter0 = counter
end

function SQNodeWaitSignal:step( context, env )
	local counter = context:getSignalCounter( self.signalId )
	if counter ~= env.counter0 then return true end
end

function SQNodeWaitSignal:getRichText()
	return string.format( '<cmd>WAIT_SIG</cmd> <signal>%s</signal>', self.signalId )
end

--------------------------------------------------------------------
registerSQNode( 'signal', SQNodeSignal   )
registerSQNode( 'wait_signal', SQNodeWaitSignal )
