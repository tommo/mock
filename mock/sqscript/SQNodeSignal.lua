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


--------------------------------------------------------------------