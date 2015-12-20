module 'mock'

--------------------------------------------------------------------
CLASS: SQNode ()
	:MODEL{
}

function SQNode:__init()
	self.parentSequence = false
	self.parentNode = false
	self.nextNode   = false
	self.prevNode   = false
end

function SQNode:getNextNode()
	return self.nextNode
end

function SQNode:getPrevNode()
	return self.prevNode
end

function SQNode:getSequence()
	return self.parentSequence
end

function SQNode:execute( context )
	context.currentNode = self
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

