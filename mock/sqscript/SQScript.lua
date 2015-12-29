module 'mock'

local ccreate, cresume, cyield, cstatus
	= coroutine.create, coroutine.resume, coroutine.yield, coroutine.status
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

function SQNode:getRoutine()
	return self.parentRoutine
end

function SQNode:isGroup()
	return false
end

function SQNode:addChild( node, idx )
	node.parentNode = self
	node.parentRoutine = self.parentRoutine
	if idx then
		table.insert( self.children, idx, node )
	else
		table.insert( self.children, node )
	end
	return node
end

function SQNode:indexOfChild( node )
	return table.index( self.children, node )
end

function SQNode:removeChild( node )
	local idx = table.index( self.children, node )
	if not idx then return false end
	table.remove( self.children, idx )
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

function SQNode:executeChildNodes( context, env )
	local children = self.children
	for i, child in ipairs( children ) do
		local res = child:execute( context )
		if res == 'jump' then return 'jump' end
	end
	return true
end

function SQNode:execute( context ) --inside a coroutine
	-- print( 'execute node', self:getClassName() )
	local env = {}
	--node enter
	local res = self:enter( context, env )
	if res == 'jump' then	return 'jump'	end
 	
 	--node step
	if res ~= false then
		local dt = 0
		while true do
			local res = self:step( context, env, dt )
			if res then break end
			dt = cyield()
		end
	end

	--children
	local res = self:executeChildNodes( context, env )
	if res == 'jump' then	return 'jump'	end

	--node exit
	return self:exit( context, env )
	
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
	table.insert( routine.labelNodes, self )
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
		context._jumpTargetNode = false
	else
		context._jumpTargetNode = targetNode
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
		'<cmd>END</cmd> <flag>%s</flag>',
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
	table.insert( self.routines, routine )
	return routine
end

function SQScript:removeRoutine( routine )
	local idx = table.index( self.routines, routine )
	if not idx then return end
	routine.parentRoutine = false
	table.remove( self.routines, idx )
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
	if self.built then return end
	self.built = true
	for i, routine in ipairs( self.routines ) do
		routine:build()
	end
end

--------------------------------------------------------------------
SQContext :MODEL{
	
}

function SQContext:__init()
	self.currentScript = false
	self.running = false
	self.paused  = false

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
	self.running = true
	self.currentScript = script
	for i, routine in ipairs( script.routines ) do
		self:executeRoutine( routine )
	end
end

function SQContext:getSignalCounter( id )
	return self.signalCounters[ id ] or 0
end

function SQContext:incSignalCounter( id )
	local v = ( self.signalCounters[ id ] or 0 ) + 1
	self.signalCounters[ id ] = v
	return v
end

local function _SQConexteCoroutineFunc( context, routine )
	local dt = cyield()
	local entryNode = routine:getRootNode()
	-- print( 'starting routine', context, routine )
	while true do
		local res = entryNode:execute( context )
		if res == 'jump' then
			local targetNode = context._jumpTargetNode
			context._jumpTargetNode = false
			if not targetNode then --END
				break
			end
			entryNode = targetNode:getParent() --TODO: use pointer instead of tree iteration.
		else
			break
		end
	end
end

function SQContext:executeRoutine( routine )
	local coroutines = self.coroutines
	local coro = ccreate( _SQConexteCoroutineFunc )
	coroutines[ routine ] = coro
	return cresume( coro, self, routine )
end

function SQContext:update( dt )
	if not self.running then return end
	if self.paused then return end
	local coroutines = self.coroutines
	local done = false
	for routine, coro in pairs( coroutines ) do
		local succ, result = cresume( coro, dt )
		if not succ then
			if not done then done = {} end
			done[ routine ] = true
			print( result )
			print( debug.traceback( coro ) )
			error( 'error in SQRoutine execution:' )
		elseif cstatus( coro ) == 'dead' then
			if not done then done = {} end
			done[ routine ] = true
		end
	end

	if done then
		for r in pairs( done ) do
			coroutines[ r ] = nil
		end
		if not next( coroutines ) then
			self.running = false
		end
	end
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
