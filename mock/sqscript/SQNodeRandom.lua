module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeRandomBranch ( SQNodeGroup )
	:MODEL{
		Field 'name'   :string();
		Field 'weight' :int();
}

function SQNodeRandomBranch:__init()
	self.name = 'Random Branch'
	self.weight = 1
end

function SQNodeRandomBranch:load( data )
	self.weight = tonumber( data.args[ 1 ] ) or 1
end

function SQNodeRandomBranch:build()
	local parent = self.parentNode
	if parent:isInstance( SQNodeRandom ) then
		self.parentRandomNode = parent
	else
		self.parentRandomNode = false
	end
end

function SQNodeRandomBranch:enter( state, env )
	local randomNode = self.parentRandomNode
	if not randomNode then return false end
	local parentEnv = state:getNodeEnvTable( randomNode )
	if parentEnv[ 'selected' ] == self then return true end
	return false
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
	self.branchProbList = {}
	self.name = 'RandomGroup'
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

function SQNodeRandom:enter( state, env )
	local jumpTo = probselect( self.branchProbList )
	env[ 'selected' ] = jumpTo
	return true
end

function SQNodeRandom:build()
	local children = self.children
	self.children = {} --rebuild children list
	local l = {}
	for i, child in ipairs( children ) do
		local branch
		if child:isInstance( SQNodeRandomBranch ) then
			branch = child
			self:addChild( branch )
		else
			branch = SQNodeRandomBranch()
			branch.weight = 1
			self:addChild( branch )
			branch:addChild( child )
		end
		local entry = { branch.weight, branch }
		l[i] = entry
	end
	self.branchProbList = l
end

registerSQNode( 'random',      SQNodeRandom  )
registerSQNode( 'prob',        SQNodeRandomBranch  )
