module 'mock'

--------------------------------------------------------------------
CLASS: EffectNode  ()
CLASS: EffectGroup ( EffectNode )
CLASS: EffectRoot  ( EffectGroup )
CLASS: EffectState ()
----------------------------------------------------------------------
--CLASS: EffectNode
--------------------------------------------------------------------
EffectNode :MODEL {
		Field 'name'     :string();
		Field 'children' :array( EffectNode ) :no_edit();
		Field 'parent'   :type( EffectNode ) :no_edit();
	}

function EffectNode:__init()
	self._built   = false
	self.parent   = false
	self.children = {}
	self.name     = self:getDefaultName()
end

function EffectNode:getDefaultName()
	return 'effect'
end

function EffectNode:getTypeName()
	return 'node'
end

function EffectNode:setName( n )
	self.name = n
end

function EffectNode:findChild( name )
	for i, c in pairs( self.children ) do
		if c.name == name then return c end
	end
	return nil
end

function EffectNode:addChild( n, idx )
	if n.parent then
		n.parent:removeChild( n )
	end
	if idx then
		table.insert( self.children, idx, n )
	else
		table.insert( self.children, n )
	end
	n.parent = self
end

function EffectNode:removeChild( n )	
	for i, c in ipairs( self.children ) do
		if c == n then
			table.remove( self.children, i )
			n.parent = false
			return
		end
	end
end

function EffectNode:getParent()
	return self.parent
end

function EffectNode:build( state )
	-- print('building', self:getClassName() )
	self:onBuild( state )
	for i, child in pairs( self.children ) do
		child:build( state )
	end
	self:postBuild( state )
	self._built = true
	return true
end

function EffectNode:onBuild( state )
end

function EffectNode:postBuild( state )
end

function EffectNode:loadIntoState( state )
	if not self._built then	self:build() end
	self:onLoad( state )	
	for i, child in pairs( self.children ) do
		child:loadIntoState( state )
	end
end

function EffectNode:onLoad( state )
end

function EffectNode:getTransformNode( fxState )
	return self:getProp( fxState )
end

function EffectNode:getColorNode( fxState )
	return self:getProp( fxState )
end

function EffectNode:getProp( fxState )
	return fxState[ self ]
end

function EffectNode:setActive( fxState, active )
end

function EffectNode:setVisible( fxState, visible )
end


----------------------------------------------------------------------
--CLASS: EffectGroup
--------------------------------------------------------------------
function EffectGroup:__init()
end

function EffectGroup:getDefaultName()
	return 'group'
end

function EffectGroup:getTypeName()
	return 'group'
end

function EffectGroup:build( state )
	for i, child in pairs( self.children ) do
		child:build( state )
	end
end

function EffectGroup:loadIntoState( state )
	for i, child in pairs( self.children ) do
		child:loadIntoState( state )
	end
end

--------------------------------------------------------------------
--CLASS: EffectRoot
--------------------------------------------------------------------

EffectRoot :MODEL {
	Field 'duration' :range( 0 );
	Field 'loop'     :boolean();	
	Field 'followEmitter' :boolean();
}

function EffectRoot:__init()
	self.duration = 0
	self.loop = false
	self.followEmitter = false
end

function EffectRoot:getDefaultName()
	return 'effect'
end

function EffectRoot:getTransformNode( fxState )
	return fxState:getTransformNode()
end

function EffectRoot:getColorNode( fxState )
	return fxState:getColorNode( )
end

function EffectRoot:getProp( fxState )
	return fxState:getProp( )
end
--------------------------------------------------------------------
updateAllSubClasses( EffectNode )
--------------------------------------------------------------------

CLASS: EffectConfig ()
	:MODEL{
		Field '_root' :type( EffectRoot ) :no_edit();
	}

function EffectConfig:__init()
	self._root = EffectRoot()
end

function EffectConfig:getRootNode()
	return self._root
end

function EffectConfig:loadIntoState( state )
	self._root:loadIntoState( state )
end

local effectNodeTypeRegistry = {}
--------------------------------------------------------------------
function registerEffectNodeType( name, clas, childTypes, topEffectNode )
	--TODO: reload on modification??	
	if type( childTypes ) == 'string' then
		childTypes = { childTypes }
	end	
	local t1 = {}
	local all = false
	if childTypes then
		for i, k in ipairs( childTypes ) do
			if k == '*' then all = true break end
			t1[ k ] = true
		end
		local _, c = next( childTypes )
		assert( type( c ) == 'string', 'child types should be specified in strings.' )
	end

	effectNodeTypeRegistry[ name ] = {
		clas          = clas,
		childTypes    = all and '*' or t1,
		topEffectNode = topEffectNode and true or false
	}

	clas.__effectName = name
end

function registerTopEffectNodeType( name, clas, childTypes )
	return registerEffectNodeType( name, clas, childTypes, true )
end

function getAvailSubEffectNodeTypes( etypeName )
	if not etypeName then etypeName = 'root' end	
	local res = { 'script' }
	-- if etypeName == 'script' then --should script on script be supported?
	-- end
	if etypeName == 'root' then
		for name, r1 in pairs( effectNodeTypeRegistry ) do
			if name ~= 'script' then
				if r1.topEffectNode then
					table.insert( res, name )
				end
			end
		end
		return res
	else --non root
		local r = effectNodeTypeRegistry[ etypeName ]
		if not r then
			_warn( 'no effect type defined', etypeName )
			return 
		end
		for name, r1 in pairs( effectNodeTypeRegistry ) do
			if name ~= 'script' then
				if r.childTypes == '*' or r.childTypes[ name ] then
					table.insert( res, name )
				end
			end
		end
		return res
	end
end

function getEffectNodeType( name )
	local entry = effectNodeTypeRegistry[ name ]
	if not entry then
		_warn( 'no effect type defined', name )
		return 
	end
	return entry.clas
end

--------------------------------------------------------------------
--Effect State
--------------------------------------------------------------------
EffectState	:MODEL{}

function EffectState:__init( emitter, config )
	--TODO: refactor this out...
	local trans = MOAITransform.new() 
	local prop  = emitter.prop
	self._emitter = emitter
	self._emitterProp  = prop
	self._trans  =  trans 
	self._config = config
	self._updateListeners = {}

	local root = config:getRootNode()
	self._followEmitter = root.followEmitter
	if root.followEmitter then
		inheritTransform( trans, prop )
	else
		prop:forceUpdate()
		trans:setLoc( prop:getLoc() )
		trans:setScl( prop:getScl() )
		trans:setRot( prop:getRot() )
	end
end

function EffectState:getTransformNode()
	return self._trans
end

function EffectState:getColorNode()
	return false
end

function EffectState:getProp()
	return self._trans
end

function EffectState:getEmitter()
	return self._emitter
end

function EffectState:linkTransform( trans )
	inheritTransform( trans, self._trans )	
end

function EffectState:linkPartition( prop )
	inheritPartition( prop, self._emitterProp )
end

function EffectState:getEffectConfig()
	return self._config
end

function EffectState:start()
	
end

function EffectState:stop()

end

function EffectState:addUpdateListener( node )
	self._updateListeners[ node ] = true
end

function EffectState:removeUpdatingListener( node )
	self._updateListeners[ node ] = nil
end

function EffectState:update( dt )
	for k in pairs( self._updateListeners ) do
		k:onUpdate( self, dt )
	end
end

--------------------------------------------------------------------
-- Asset Loader
--------------------------------------------------------------------
function loadEffectConfig( node )
	local defData   = loadAssetDataTable( node:getObjectFile('def') )
	local config = deserialize( nil, defData )
	return config
end

registerAssetLoader( 'effect', loadEffectConfig )
