module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeRandomBranch ( SQNodeBranch )
	:MODEL{
		Field 'weight' :int();
}

function SQNodeRandomBranch:__init()
	self.weight = 1
end

function SQNodeRandomBranch:exit( context, env )
	context:setJumpTarget( self.parentNode:getNextSibling() )
	return 'jump'
end

function SQNodeRandomBranch:getRichText()
	return string.format( '<branch>%s</branch> weight:<number>%d</number>', self.name, self.weight )
end

function SQNodeRandomBranch:getIcon()
	return 'sq_node_branch'
end

function SQNodeRandomBranch:isBuiltin()
	return true
end

--------------------------------------------------------------------
CLASS: SQNodeRandom ( SQNodeGroup )
	:MODEL{}

function SQNodeRandom:__init()
	self.brancheProbList = {}
end

function SQNodeRandom:acceptSubNode( name )
	return name == 'random_branch'
end

function SQNodeRandom:getIcon()
	return 'sq_node_random'
end

function SQNodeRandom:getRichText()
	return string.format( '<cmd>RANDOM</cmd> [ <group>%s</group> ]', self.name )
end

function SQNodeRandom:enter( context, env )
	local jumpTo = probselect( self.brancheProbList )
	if jumpTo then
		context:setJumpTarget( jumpTo )
		return 'jump'
	else
		return true
	end
end

function SQNodeRandom:build()
	local l = {}
	for i,child in ipairs( self.children ) do
		local entry = { child.weight, child }
		l[i] = entry
	end
	self.brancheProbList = l
end

registerSQNode( 'random',         SQNodeRandom  )
registerSQNode( 'random_branch',  SQNodeRandomBranch  )
