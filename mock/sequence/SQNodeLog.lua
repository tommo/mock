module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeLog ( SQNode )
	:MODEL{
		Field 'text'
	}

function SQNodeLog:__init()
	self.text = 'message'
end

function SQNodeLog:enter( context, env )
	print( self.text )
end

