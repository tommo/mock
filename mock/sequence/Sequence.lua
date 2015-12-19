module 'mock'

--------------------------------------------------------------------
CLASS: SQNode ()
	:MODEL{
}

function SQNode:execute( context )
end

function SQNode:getName()
	return 'node'
end


--------------------------------------------------------------------
CLASS: Sequence ()
	:MODEL{}

function Sequence:__init()
	self.rootNode = SQNode()
end

