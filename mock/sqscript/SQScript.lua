module 'mock'

local ccreate, cresume, cyield, cstatus
	= coroutine.create, coroutine.resume, coroutine.yield, coroutine.status

local insert, remove = table.insert, table.remove
--------------------------------------------------------------------

CLASS: SQNode ()
CLASS: SQRoutine ()
CLASS: SQScript ()

CLASS: SQContext ()



--------------------------------------------------------------------
SQNode :MODEL{
		Field 'index'   :int() :no_edit(); 
		Field 'comment' :string() :no_edit(); 
		Field 'active'  :boolean() :no_edit(); 

		Field 'parentRoutine' :type( SQRoutine ) :no_edit();
		Field 'parentNode' :type( SQNode ) :no_edit();
		Field 'children'   :array( SQNode ) :no_edit();
}

function SQNode:__init()
	self.parentRoutine = false
	
	self.index      = 0
	self.active     = true
	self.parentNode = false
	self.children   = {}

	self.comment    = ''

end

function SQNode:getRoot()
	return self.parentRoutine:getRootNode()
end

function SQNode:getChildren()
	return self.children
end

function SQNode:getParent()
	return self.parentNode
end

function SQNode:getNextSibling()
	local p = self.parentNode
	local siblings = p and p.children
	return siblings[ self.index + 1 ]
end

function SQNode:getRoutine()
	return self.parentRoutine
end

function SQNode:isGroup()
	return false
end

function SQNode:canInsert()
	return false
end

function SQNode:isBuiltin()
	return false
end

function SQNode:initFromEditor()
end

function SQNode:addChild( node, idx )
	node.parentNode = self
	node.parentRoutine = self.parentRoutine
	if idx then
		insert( self.children, idx, node )
	else
		insert( self.children, node )
	end
	return node
end

function SQNode:indexOfChild( node )
	return table.index( self.children, node )
end

function SQNode:removeChild( node )
	local idx = table.index( self.children, node )
	if not idx then return false end
	remove( self.children, idx )
	node.parentNode = false
	node.parentRoutine = false	
	return true
end

function SQNode:getName()
	return 'node'
end

function SQNode:getComment()
	return self.comment
end

function SQNode:getRichText()
	return 'SQNode'
end

function SQNode:getIcon()
	return false
end

function SQNode:setComment( c )
	self.comment = c
end

function SQNode:enter( context, env )
	return true
end

function SQNode:step( context, env, dt )
	return true
end

function SQNode:exit( context, env )
	return true
end

function SQNode:_build()
	self:build()
	for i, child in ipairs( self.children ) do
		child.index = i
		child:_build()
	end
end

function SQNode:build()
end

--------------------------------------------------------------------
CLASS: SQNodeGroup ( SQNode )
	:MODEL{
		Field 'name' :string();
}

function SQNodeGroup:__init()
	self.name = 'group'
end

function SQNodeGroup:isGroup()
	return true
end

function SQNodeGroup:canInsert()
	return true
end


function SQNodeGroup:getRichText()
	return string.format(
		'[ <group>%s</group> ]',
		self.name
		)
end

function SQNodeGroup:getIcon()
	return 'sq_node_group'
end


--------------------------------------------------------------------
CLASS: SQNodeLabel( SQNode )
	:MODEL{
		Field 'id' :string();
}

function SQNodeLabel:__init()
	self.id = 'label'
end

function SQNodeLabel:getRichText()
	return string.format(
		'<label>%s</label>',
		self.id
		)
end

function SQNodeLabel:getIcon()
	return 'sq_node_label'
end

function SQNodeLabel:build()
	local routine = self:getRoutine()
	insert( routine.labelNodes, self )
end


--------------------------------------------------------------------
CLASS: SQNodeGoto( SQNode )
	:MODEL {
		Field 'label' :string();
}

function SQNodeGoto:__init()
	self.label = 'label'
end

function SQNodeGoto:enter( context, env )
	local routine = self:getRoutine()
	local targetNode = routine:findLabelNode( self.label )
	if not targetNode then
		_warn( 'target label not found', self.label )
		context:setJumpTarget( false )
	else
		context:setJumpTarget( targetNode )
	end
	return 'jump'
end

function SQNodeGoto:getRichText()
	return string.format(
		'<cmd>GOTO</cmd> <label>%s</label>',
		self.label
		)
end

function SQNodeGoto:getIcon()
	return 'sq_node_goto'
end



---------------------------------------------------------------------
CLASS: SQNodeEnd( SQNode )
	:MODEL{
		Field 'stopAllRoutines' :boolean()
}

function SQNodeEnd:__init()
	self.stopAllRoutines = false
end

function SQNodeEnd:enter( context )
	if self.stopAllRoutines then
		context:stop()
		return 'jump'
	else
		context._jumpTargetNode = false --jump to end
		return 'jump'
	end
end

function SQNodeEnd:getRichText()
	return string.format(
		'<end>END</end> <flag>%s</flag>',
		self.stopAllRoutines and 'All Routines' or ''
		)
end

function SQNodeEnd:getIcon()
	return 'sq_node_end'
end


--------------------------------------------------------------------
CLASS: SQNodeRoot( SQNodeGroup )



--------------------------------------------------------------------
SQRoutine :MODEL{
		Field 'name' :string();
		Field 'comment' :string();

		Field 'rootNode' :type( SQNode ) :no_edit();
		Field 'parentScript' :type( SQScript ) :no_edit();
}

function SQRoutine:__init()
	self.parentScript   = false

	self.rootNode = SQNodeRoot()	
	self.rootNode.parentRoutine = self

	self.name = 'unnamed'
	self.comment = ''

	self.labelNodes = {}
end

function SQRoutine:findLabelNode( id )
	for i, node in ipairs( self.labelNodes ) do
		if node.id == id then return node end
	end
	return nil
end

function SQRoutine:getName()
	return self.name
end

function SQRoutine:setName( name )
	self.name = name
end

function SQRoutine:getComment()
	return self.comment
end

function SQRoutine:setComment( c )
	self.comment = c
end

function SQRoutine:getRootNode()
	return self.rootNode
end

function SQRoutine:addNode( node, idx )
	return self.rootNode:addChild( node, idx )
end

function SQRoutine:removeNode( node )
	return self.rootNode:removeChild( node )
end

function SQRoutine:execute( context )
	return context:executeRoutine( self )
end

function SQRoutine:build()
	self.rootNode:_build()
end


--------------------------------------------------------------------
SQScript :MODEL{
		Field 'comment';	
		Field 'routines' :array( SQRoutine ) :no_edit();
}

function SQScript:__init()
	self.routines = {}
	self.comment = ''
	self.built = false
end

function SQScript:addRoutine( routine )
	local routine = routine or SQRoutine()
	routine.parentScript = self
	insert( self.routines, routine )
	return routine
end

function SQScript:removeRoutine( routine )
	local idx = table.index( self.routines, routine )
	if not idx then return end
	routine.parentRoutine = false
	remove( self.routines, idx )
end

function SQScript:getRoutines()
	return self.routines
end

function SQScript:getComment()
	return self.comment
end

function SQScript:_postLoad( data )
end

function SQScript:build()
	if self.built then return true end
	self.built = true
	for i, routine in ipairs( self.routines ) do
		routine:build()
	end
	return true
end


--------------------------------------------------------------------
CLASS: SQRoutineContext ()
 
function SQRoutineContext:__init( context, routine )
	self.parentContext = context
	self.routine = routine
	self.running = true
	self.jumpTarget = false

	self.currentParentNode = false
	self.currentNode = false
	self.currentNodeEnv = false

	local rootNode = routine:getRootNode()
	self.currentNode  = rootNode
	self.currentQueue = {}
	self.index = 1

	self.nodeEnvMap = {}
end


function SQRoutineContext:getSignalCounter( id )
	return self.parentContext:getSignalCounter( id )
end

function SQRoutineContext:incSignalCounter( id )
	return self.parentContext:incSignalCounter( id )
end

function SQRoutineContext:getEnv( key, default )
	return self.parentContext:getEnv( key, default )
end

function SQRoutineContext:setEnv( key, value )
	return self.parentContext:setEnv( key, value )
end


function SQRoutineContext:update( dt )
	if not self.running then return end
	self:updateNode( dt )
end

function SQRoutineContext:updateNode( dt )
	local node = self.currentNode
	if node then
		local env = self.currentNodeEnv
		local res = node:step( self, env, dt )
		if res then
			if res == 'jump' then
				return self:doJump()
			end
			return self:exitNode()
		end
	else
		return self:nextNode()
	end
end

function SQRoutineContext:nextNode()
	local index1 = self.index + 1
	local node1 = self.currentQueue[ index1 ]
	if not node1 then
		return self:exitGroup()
	end
	self.index = index1
	self.currentNode = node1
	local env = {}
	self.currentNodeEnv = env
	local res = node1:enter( self, env )
	if res == 'jump' then
		return self:doJump()
	end
	return self:updateNode( 0 )
end

function SQRoutineContext:exitNode( fromGroup )
	local node = self.currentNode
	if node:isGroup() then --Enter group
		self.nodeEnvMap[ node ] = self.currentNodeEnv
		self.index = 0
		self.currentQueue = node.children
	else
		local res = node:exit( self, self.currentNodeEnv )
		if res == 'jump' then
			return self:doJump()
		end
	end
	return self:nextNode()
end

function SQRoutineContext:exitGroup()
	--exit group node
	local groupNode = self.currentNode.parentNode
	local env = self.nodeEnvMap[ groupNode ] or {}
	local res = groupNode:exit( self, env )
	if res == 'jump' then
		return self:doJump()
	elseif res == 'loop' then
		--Loop
		self.index = 0
	else
		local parent = groupNode.parentNode
		if not parent then 
			self.running = false
			return true
		end
		self.currentQueue = parent.children
		self.index = groupNode.index
	end
	return self:nextNode()
end

function SQRoutineContext:setJumpTarget( node )
	self.jumpTarget = node
end

function SQRoutineContext:doJump()
	local target = self.jumpTarget
	if not target then
		self.running = false
		return false
	end

	self.jumpTarget = false
	local parentNode = target.parentNode
	self.currentQueue = parentNode.children
	self.index = target.index - 1
	return self:nextNode()
	
end

--------------------------------------------------------------------
SQContext :MODEL{
	
}

function SQContext:__init()
	self.currentScript = false
	self.running = false
	self.paused  = false

	self.routineContexts = {}
	self.coroutines = {}
	self.signalCounters = {}
	self.env = {}
end

function SQContext:getEnv( key, default )
	local v = self.env[ key ]
	if v == nil then return default end
	return v
end

function SQContext:setEnv( key, value )
	self.env[ key ] = value
end

function SQContext:getSignalCounter( id )
	return self.signalCounters[ id ] or 0
end

function SQContext:incSignalCounter( id )
	local v = ( self.signalCounters[ id ] or 0 ) + 1
	self.signalCounters[ id ] = v
	return v
end


function SQContext:isPaused()
	return self.paused
end

function SQContext:pause( paused )
	self.paused = paused ~= false
end

function SQContext:isRunning()
	return self.running
end

function SQContext:isDone()
	return not self.running
end

function SQContext:stop()
	self.running = false
end

function SQContext:loadScript( script )
	script:build()
	self.running = true
	self.currentScript = script
	for i, routine in ipairs( script.routines ) do
		local routineContext = SQRoutineContext( self, routine )
		insert( self.routineContexts, routineContext )
	end
end

function SQContext:update( dt )
	if not self.running then return end
	if self.paused then return end
	local running = false
	for i, routineContext in ipairs( self.routineContexts ) do
		running = running or routineContext.running
		routineContext:update( dt )
	end
	if not running then self.running = false end
end

--------------------------------------------------------------------
local SQNodeRegistry = {}
local defaultOptions = {}
function registerSQNode( name, clas, options )
	options = options or {}
	local entry0 = SQNodeRegistry[ name ]
	if entry0 then
		_warn( 'duplicated SQNode:', name )
	end
	SQNodeRegistry[ name ] = {
		clas     = clas,
		comment  = options[ 'comment' ] or ''
	}
end

function findInSQNodeRegistry( name )
	return SQNodeRegistry[ name ]
end

function getSQNodeRegistry()
	return SQNodeRegistry
end



--------------------------------------------------------------------
--------------------------------------------------------------------
function loadSQScriptFromRaw( data )
	local script = mock.deserialize( nil, data )
	script:_postLoad()
	script:build()
	return script
end

function loadSQScriptFromString( strData )
	local t = MOAIJsonParser.decode( strData )
	return loadSQScriptFromRaw( t )
end

function loadSQScript( node )
	local data   = mock.loadAssetDataTable( node:getObjectFile('data') )
	return loadSQScriptFromRaw( data )
end

--------------------------------------------------------------------
registerSQNode( 'group', SQNodeGroup )
registerSQNode( 'label', SQNodeLabel )
registerSQNode( 'end',   SQNodeEnd   )
registerSQNode( 'goto',  SQNodeGoto  )

mock.registerAssetLoader( 'sq_script', loadSQScript )
