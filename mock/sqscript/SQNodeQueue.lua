module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeQueueEntry ( SQNodeGroup )
	:MODEL{
		Field 'name'   :string();
		Field 'weight' :int();
}

function SQNodeQueueEntry:__init()
	self.name = 'Queue Entry'
end

function SQNodeQueueEntry:build()
	local parent = self.parentNode
	if parent:isInstance( SQNodeQueue ) then
		self.parentQueueNode = parent
	else
		self.parentQueueNode = false
	end
end

function SQNodeQueueEntry:enter( state, env )
	local QueueNode = self.parentQueueNode
	if not QueueNode then return false end
	local parentEnv = state:getNodeEnvTable( QueueNode )
	if parentEnv[ 'selected' ] == self then return true end
	return false
end

--------------------------------------------------------------------
CLASS: SQNodeQueue ( SQNodeGroup )
	:MODEL{}

function SQNodeQueue:__init()
	self.entries = {}
	self.name = 'QueueGroup'
end

function SQNodeQueue:getRichText()
	return string.format( '<cmd>QUEUE</cmd> [ <group>%s</group> ]', self.name )
end

function SQNodeQueue:enter( state, env )
	local env2 = state:getGlobalNodeEnvTable( self )
	local idx = env2[ 'current' ] or 0
	local jumpTo = self.entries[ idx + 1 ]
	env2[ 'current' ] = ( idx + 1 ) % #self.entries
	env[ 'selected' ] = jumpTo
	return true
end

function SQNodeQueue:build()
	local children = self.children
	self.children = {} --rebuild children list
	local l = {}
	for i, child in ipairs( children ) do
		local entry
		if child:isInstance( SQNodeQueueEntry ) then
			entry = child
			self:addChild( entry )
		else
			entry = SQNodeQueueEntry()
			self:addChild( entry )
			entry:addChild( child )
		end
		l[i] = entry
	end
	self.entries = l
end

registerSQNode( 'queue',      SQNodeQueue  )
