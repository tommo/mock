--------------------------------------------------------------------
-- The basic element of scenegraph.
-- @classmod Entity

module 'mock'
--------------------------------------------------------------------
local insert, remove = table.insert, table.remove
local pairs, ipairs  = pairs, ipairs
local unpack = unpack
local next   = next
local type   = type

--------------------------------------------------------------------
----- ENTITY CLASS
--------------------------------------------------------------------

---------------------------------------------------------------------
CLASS: Entity ( Actor )
	:MODEL{
		Field '__prefabId':string() :no_edit();
		Field '_priority' :int() :no_edit()  :set('setPriority');
		-- Field '_editLocked' :boolean() :no_edit();
		
		----
		Field 'name'      :string()  :getset('Name');
		'----';
		Field 'tags'      :string()  :getset('Tags');
		'----';
		Field 'visible'   :boolean() :get('isLocalVisible') :set('setVisible');
		-- Field 'active'    :boolean() :get('isLocalActive')  :set('setActive');		
		Field 'layer'     :type('layer')  :getset( 'Layer' ) :no_nil();
		'----';
		Field 'loc'       :type('vec3') :getset('Loc') :label('Loc'); 
		Field 'rot'       :type('vec3') :getset('Rot') :label('Rot');
		Field 'scl'       :type('vec3') :getset('Scl') :label('Scl') :meta{ step = 0.1 };
		Field 'piv'       :type('vec3') :getset('Piv') :label('Piv');
		'----';
		Field 'color'    :type('color')  :getset('Color') ;
	}

wrapWithMoaiPropMethods( Entity, '_prop' )
local setupMoaiTransform = setupMoaiTransform

--------------------------------------------------------------------
-------init
--------------------------------------------------------------------
--change this to use other MOAIProp subclass as entity prop
local newProp = MOCKProp.new
function Entity:_createEntityProp()
	return newProp()
end

--create proxy object for ide editor
function Entity:_createTransformProxy()
	return false
end

local _PRIORITY = 1
function Entity:__init()
	local _prop = self:_createEntityProp()
	self._prop       = _prop

	_PRIORITY = _PRIORITY + 1
	self._priority   = _PRIORITY
	_prop:setPriority( _PRIORITY )

	self._maxComponentID = 0

	self.scene       = false --not loaded yet
	self.components  = {}
	self.children    = {}
	-- self.timers      = false
	self.name        = false
	
	--TODO: move this into MOCKProp
	self.active      = true
	self.localActive = true
	self.started     = false
	self._entityGroup = false
	self._editLocked  = false
	self._comCache    = false
	
end

function Entity:_insertIntoScene( scene, layer )
	self.scene = assert( scene )
	local layer = layer or self.layer
	if type(layer) == 'string' then
		layer = scene:getLayer( layer )
	end
	local entityListener = scene.entityListener

	self.layer = layer
	scene.entities[ self ] = true

	local copy = {} --there might be new components attached inside component starting
	for com in pairs( self.components ) do
		copy[ com ] = true
	end 
	for com in pairs( copy ) do
		if not com._entity then
			com._entity = self
			local onAttach = com.onAttach
			if onAttach then onAttach( com, self ) end
			if entityListener then
				entityListener( 'attach', self, com )
			end
		end
	end

	if self.onLoad then
		self:onLoad()
	end

	if self.onUpdate then
		scene:addUpdateListener( self )
	end
	
	local name = self.name
	if name then
		scene:changeEntityName( self, false, name )
	end

	--pre-added children
	for child in pairs( self.children ) do
		if not child.scene then
			child:_insertIntoScene( scene, child.layer or layer )
		end
	end
	scene.pendingStart[ self ] = true
	
	--callback
	if entityListener then entityListener( 'add', self, nil ) end
end

function Entity:getProp( role )
	return self._prop
end

function Entity:getEntityGroup( searchParent )
	if searchParent ~= false then
		local p = self
		while p do
			local group = p._entityGroup
			if group then return group end
			p = p.parent
		end
		return false
	else
		return self._entityGroup
	end
end

--------------------------------------------------------------------
------ Destructor
--------------------------------------------------------------------

--- Destroy the Entity if it's inserted into a scene, deferred. ( scene checking )
function Entity:tryDestroy()
	if not self.scene then return end
	return self:destroy()
end

--- Destroy the Entity, deferred. ( without scene checking, unsafe )
function Entity:destroy()
	assert( self.scene )
	local scene = self.scene
	scene.pendingDestroy[ self ] = true
	scene.pendingStart[ self ] = nil
	
	for child in pairs( self.children ) do
		child:destroy()
	end

	if self.name then
		local entitiesByName = scene.entitiesByName
		if entitiesByName[ self.name ] == self then
			entitiesByName[ self.name ] = nil
		end
	end
end

--- Destroy the Entity later.
-- @p float delay delaying time to the destruction in seconds
function Entity:destroyLater( delay )
	assert( self.scene )
	self.scene.laterDestroy[ self ]= self:getTime() + delay
end

--- Destroy the Entity immediately.
function Entity:destroyWithChildrenNow()
	for child in pairs( self.children ) do
		child:destroyWithChildrenNow()
	end
	self:destroyNow()
end

function Entity:destroyAllNow()
	return self:destroyWithChildrenNow()
end

function Entity:destroyNow()
	local scene     = self.scene
	local onDestroy = self.onDestroy
	if not scene then return end

	self:disconnectAll()
	self:clearCoroutines()
	local entityListener = scene.entityListener
	
	--timers
	local timers = self.timers
	if timers then
		for timer in pairs( timers ) do
			timer:stop()
		end
	end

	if onDestroy then onDestroy( self )	end

	local components = self.components
	while true do
		local com = next( components )
		if not com then break end
		components[ com ] = nil
		local onDetach = com.onDetach
		if entityListener then
			entityListener( 'detach', self, com )
		end
		if onDetach then
			onDetach( com, self )
		end
		com._entity = nil
	end
	-- for com in pairs( components ) do
	-- 	components[ com ] = nil
	-- 	local onDetach = com.onDetach
	-- 	if onDetach then
	-- 		onDetach( com, self )
	-- 	end
	-- end
	
	if self.parent then
		self.parent.children[self] = nil
		self.parent = nil
	end

	if self._entityGroup then
		self._entityGroup:removeEntity( self )
	end
	
	scene:removeUpdateListener( self )
	scene.entities[ self ] = nil
	
	--callback
	if entityListener then entityListener( 'remove', self, scene, layer ) end

	self.scene      = false
	self.components = false	
end

--------------------------------------------------------------------
------- Component Attach/Detach
--------------------------------------------------------------------

--- Attach a component
-- @p Component com the component instance to be attached
-- @ret Component the component attached ( same as the input )
function Entity:attach( com )
	if not self.components then 
		_error('attempt to attach component to a dead entity')
		return com
	end
	if self.components[ com ] then
		_log( self.name, tostring( self.__guid ), com:getClassName() )
		error( 'component already attached!!!!' )
	end
	self._comCache = false
	self.components[ com ] = com:getClass()
	com._componentID = self._maxComponentID
	self._maxComponentID = self._maxComponentID + 1
	if self.scene then
		com._entity = self		
		local onAttach = com.onAttach
		if onAttach then onAttach( com, self ) end
		local entityListener = self.scene.entityListener
		if entityListener then
			entityListener( 'attach', self, com )
		end
		if self.started then
			local onStart = com.onStart
			if onStart then onStart( com, self ) end
		end
	end
	return com
end

--- Attach an internal component ( invisible in the editor )
-- @p Component com the component instance to be inserted
-- @ret Component the component attached ( same as the input )
function Entity:attachInternal( com )
	com.FLAG_INTERNAL = true
	return self:attach( com )
end

--- Attach an array of components
-- @p {Component} components an array of components to be attached
function Entity:attachList( l )
	for i, com in ipairs( l ) do
		self:attach( com )
	end
end

--- Detach given component
-- @p Component com component to be detached
-- @p ?string reason reason to detaching
function Entity:detach( com, reason, _skipDisconnection )
	local components = self.components
	if not components[ com ] then return end
	components[ com ] = nil
	if self.scene then
		local entityListener = self.scene.entityListener
		if entityListener then
			entityListener( 'detach', self, com )
		end
		local onDetach = com.onDetach
		if not _skipDisconnection then
			self:disconnectAllForObject( com )
		end
		if onDetach then onDetach( com, self, reason ) end
	end
	com._entity = nil
	return com
end

--- Detach all the components
-- @p ?string reason reason to detaching
function Entity:detachAll( reason )
	local components = self.components
	while true do
		local com = next( components )
		if not com then break end
		self:detach( com, reason, true )
	end
end


--- Detach all components of given type
-- @p string|Class comType component type to be looked for
-- @p ?string reason reason to detaching
function Entity:detachAllOf( comType, reason )
	for i, com in ipairs( self:getAllComponentsOf( comType ) ) do
		self:detach( com, reason )
	end
end

--- Detach all components of given type later
-- @p string|Class comType component type to be looked for
function Entity:detachAllOfLater( comType )
	for i, com in ipairs( self:getAllComponentsOf( comType ) ) do
		self:detachLater( com )
	end
end

--- Detach the component in next update cycle
-- @p Component com the component to be detached
function Entity:detachLater( com )
	if self.scene then
		self.scene.pendingDetach[ com ] = true
	end
end

--- Get the component table [ com ] = Class
-- @return the component table
function Entity:getComponents()
	return self.components
end


local function componentSortFunc( a, b )
	return ( a._componentID or 0 ) < ( b._componentID or 0 )
end
--- Get the sorted component list
-- @ret {Component} the sorted component array
function Entity:getSortedComponentList()
	local list = {}
	local i = 0
	for com in pairs( self.components ) do
		insert( list , com )
	end
	table.sort( list, componentSortFunc )
	return list
end

--- Get the first component of asking type
-- @p Class clas the component class to be looked for
-- @ret Component|nil
function Entity:getComponent( clas )
	if not self.components then return nil end
	for com, comType in pairs( self.components ) do
		if comType == clas then return com end
		if isClass( comType ) and comType:isSubclass( clas ) then return com end
	end
	return nil
end

--- Get component by alias
-- @p string alias alias to be looked for
-- @ret Component the found component
function Entity:getComponentByAlias( alias )
	if not self.components then return nil end
	for com, comType in pairs( self.components ) do
		if com._alias == alias then return com end
	end
	return nil
end

--- Get component by class name
-- @p string name component class name to be looked for
-- @ret Component the found component
function Entity:getComponentByName( name )
	if not self.components then return nil end
	for com, comType in pairs( self.components ) do
		while comType do
			if comType.__name == name then return com end		
			comType = comType.__super
		end
	end
	return nil
end


--- Get component either by class name or by class
-- @p nil|string|Class  component type to be looked for, return the first component if no target specified.
-- @ret Component the found component
function Entity:com( id )
	local components = self.components
	if not components then return nil end
	if not id then return next( components ) end
	
	local cache = self._comCache
	if not cache then cache = {} self._comCache = cache end
	
	local com = cache[ id ]
	if com ~= nil then
		return com
	end

	local tt = type(id)
	if tt == 'string' then
		com = self:getComponentByName( id ) or false
	elseif tt == 'table' then
		com = self:getComponent( id ) or false
	else
		_error( 'invalid component id', tostring(id) )
	end

	cache[ id ] = com
	return com
end

--- Check if the entity has given component type
-- @p Class  component type to be looked for
-- @ret boolean result
function Entity:hasComponentOf( clas )
	if self:getComponent( clas ) then return true end
	return false
end

--- Get all components of given type, by class or by class name
-- @p string|Class  component type to be looked for
-- @ret {Component} array of result
function Entity:getAllComponentsOf( id )

	local found = {}
	if not self.components then return found end

	local tt = type(id)
	if tt == 'string' then
		local clasName = id
		for com, comType in pairs( self.components ) do
			while comType do
				if comType.__name == clasName then 
					table.insert(found, com)
					break
				end		
				comType = comType.__super
			end
		end
	elseif tt == 'table' then
		local clasBody = id
		for com, comType in pairs( self.components ) do
			if comType == clasBody then 
				table.insert(found, com) 
			elseif isClass( comType ) and comType:isSubclass( clasBody ) then 
				table.insert(found, com) 
			end
		end
	end

	return found
end


--- Create a 'each' accessor for all the attached components
-- @return a 'each' accessor
-- @usage entity:eachComponet():setActive()
function Entity:eachComponent()
	local list = table.keys( self:getComponents() )
	return eachT( list )
end

--- Create a 'each' accessor for all the attached components with given type
-- @p string|Class component type
-- @return a 'each' accessor
function Entity:eachComponentOf( id )
	local list = self:getAllComponentsOf( id )
	return eachT( list )
end

--- Print attached Components
function Entity:printComponentClassNames()
	for com in pairs( self.components ) do
		print( com:getClassName() )
	end
end


--------------------------------------------------------------------
------- Attributes Links
--------------------------------------------------------------------
local inheritTransformColor = inheritTransformColor
local inheritTransform      = inheritTransform
local inheritColor          = inheritColor
local inheritVisible        = inheritVisible
local inheritLoc            = inheritLoc

function Entity:_attachProp( p, role )
	local _prop = self:getProp( role )
	inheritTransformColorVisible( p, _prop )
	self.layer:insertProp( p )
	--TODO: better solution on scissor?
	if self.scissorRect then p:setScissorRect( self.scissorRect ) end
	return p
end

function Entity:_attachTransform( t, role )
	local _prop = self:getProp( role )
	inheritTransform( t, _prop )
	return t
end

function Entity:_attachLoc( t, role )
	local _prop = self:getProp( role )
	inheritLoc( t, _prop )
	return t
end

function Entity:_attachColor( t, role )
	local _prop = self:getProp( role )
	inheritColor( t, _prop )
	return t
end

function Entity:_attachVisible( t, role )
	local _prop = self:getProp( role )
	inheritVisible( t, _prop )
	return t
end

function Entity:_insertPropToLayer( p )
	self.layer:insertProp( p )
	return p
end

function Entity:_detachProp( p, role )
	self.layer:removeProp( p )
end

function Entity:_detachVisible( t, role )
	local _prop = self:getProp( role )
	clearInheritVisible( t, _prop )
end

function Entity:_detachColor( t, role )
	local _prop = self:getProp( role )
	clearInheritColor( t, _prop )
end


--------------------------------------------------------------------
------ Child Entity
--------------------------------------------------------------------

--- Add a sibling entity
-- @p Entity entity entity to be added
-- @p[opt] string layerName name of target layer, default is the same as _self_
function Entity:addSibling( entity, layerName )	
	if self.parent then
		return self.parent:addChild( entity, layerName )
	else
		return self.scene:addEntity( entity, layerName )
	end
end

function Entity:_attachChildEntity( child )
	local _prop = self._prop
	local _p1   = child._prop
	inheritTransformColorVisible( _p1, _prop )
end

function Entity:_detachChildEntity( child )
	local _p1   = child._prop
	clearInheritTransform( _p1 )
	clearInheritColor( _p1 )
	clearInheritVisible( _p1 )
end

function Entity:addChild( entity, layerName )
	self.children[ entity ] = true
	entity.parent = self

	--TODO: better solution on scissor?
	if self.scissorRect then entity:_setScissorRect( self.scissorRect ) end
	--attach transform/color
	self:_attachChildEntity( entity )

	local scene = self.scene

	if scene then
		local targetLayer
		if layerName then 
			targetLayer = scene:getLayer( layerName )
		else
			targetLayer = entity.layer or self.layer
		end
		entity:_insertIntoScene( scene, targetLayer )
	else
		entity.layer = layerName or entity.layer or self.layer
	end

	return entity
end

function Entity:addInternalChild( e, layer )
	e.FLAG_INTERNAL = true
	return self:addChild( e, layer )
end

function Entity:isChildOf( e )
	local parent = self.parent
	while parent do
		if parent == e then return true end
		parent = parent.parent
	end
	return false
end

function Entity:hasChild( e )
	return e:isChildOf( self )
end

function Entity:getChildren()
	return self.children
end

function Entity:clearChildren()
	local children = self.children
	while true do
		local child = next( children )
		if not child then return end
		children[ child ] = nil
		child:destroy()
	end
end

function Entity:clearChildrenNow()
	local children = self.children
	while true do
		local child = next( children )
		if not child then return end
		children[ child ] = nil
		child:destroyWithChildrenNow()
	end
end

function Entity:getParent()
	return self.parent
end

function Entity:getParentOrGroup() --for editor, return parent entity or group
	return self.parent or self._entityGroup
end

function Entity:reparentGroup( group )
	if self._entityGroup then
		self._entityGroup:removeEntity( self )
	end
	group:addEntity( self )
end

function Entity:reparent( entity )
	--assert this entity is already inserted
	assert( self.scene , 'invalid usage of reparent' )
	local parent0 = self.parent
	if parent0 then
		parent0.children[ self ] = nil
		parent0:_detachChildEntity( self )
	end
	self.parent = entity
	if entity then
		entity.children[ self ] = true
		entity:_attachChildEntity( self )
	end
end

function Entity:findEntity( name )
	return self.scene:findEntity( name )
end

function Entity:findEntityCom( entName, comId )
	local ent = self:findEntity( entName )
	if ent then return ent:com( comId ) end
	return nil
end

function Entity:findSibling( name )
	local parent = self.parent
	if not parent then return nil end
	for child in pairs( parent.children ) do
		if child.name == name and child ~= self then return child end
	end
	return nil
end

function Entity:findChildCom( name, comId, deep )
	local ent = self:findChild( name, deep )
	if ent then return ent:com( comId ) end
	return nil
end

function Entity:findChild( name, deep )
	for child in pairs( self.children ) do
		if child.name == name then return child end
		if deep then
			local c = child:findChild( name, deep )
			if c then return c end
		end
	end
	return nil
end

function Entity:findChildByClass( clas, deep )
	for child in pairs( self.children ) do
		if child:isInstance( clas ) then return child end
		if deep then
			local c = child:findChildByClass( clas, deep )
			if c then return c end
		end
	end
	return nil
end

function Entity:findChildByPath( path )
	local e = self
	for part in string.gsplit( path, '/' ) do
		e = e:findChild( part, false )
		if not e then return nil end
	end
	return e
end

function Entity:findEntityByPath( path )
	local e = false
	for part in string.gsplit( path, '/' ) do
		if not e then
			e = self:findEntity( part )
		else
			e = e:findChild( part, false )
		end
		if not e then return nil end
	end
	return e
end

--------------------------------------------------------------------
------ Meta
--------------------------------------------------------------------
function Entity:getPriority()
	return self._priority
end

function Entity:setPriority( p )
	self._priority = p
	self._prop:setPriority( p )
end

function Entity:getTime()
	return self.scene:getTime()
end

function Entity:setName( name )
	if self.scene then
		local prevName = self.name
		self.scene:changeEntityName( self, prevName, name )
		self.name = name
	else
		self.name = name
	end
	return self
end

function Entity:getName()
	return self.name
end

function Entity:getScene()
	return self.scene
end

function Entity:getActionRoot()
	if self.scene then return self.scene:getActionRoot() end
	return nil
end

function Entity:getFullName()
	if not self.name then return false end
	local output = self.name
	local n0 = self
	local n = n0.parent
	while n do
		output = (n.name or '<noname>')..'/'..output
		n0 = n
		n = n0.parent
	end
	if n0._entityGroup and not n0._entityGroup.isRoot then
		local groupName = n0._entityGroup:getFullName()
		return groupName..'::'..output
	end
	return output
end

function Entity:getLayer()
	if not self.layer then return nil end
	if type( self.layer ) == 'string' then return self.layer end
	return self.layer.name
end

function Entity:setLayer( layerName )
	if self.scene then
		local layer = self.scene:getLayer( layerName )
		assert( layer, 'layer not found:' .. layerName )
		self.layer = layer
		for com in pairs( self.components ) do
			local setLayer = com.setLayer
			if setLayer then
				setLayer( com, layer )
			end
		end
	else
		self.layer = layerName --insert later
	end
end

--------------------------------------------------------------------
function Entity:setTags( t )
	self._tags = t
end

function Entity:getTags()
	return self._tags
end

function Entity:hasTag( t )
	if not self._tags then return false end
	return self._tags:find( t )
end

--------------------------------------------------------------------
---------Visibility Control
--------------------------------------------------------------------
function Entity:isVisible()
	return self._prop:getAttr( MOAIProp.ATTR_VISIBLE ) == 1
end

function Entity:isLocalVisible()
	local vis = self._prop:getAttr( MOAIProp.ATTR_LOCAL_VISIBLE )
	return vis == 1
end

function Entity:setVisible( visible )
	self._prop:setVisible( visible )
end

function Entity:show()
	self:setVisible( true )
end

function Entity:hide()
	self:setVisible( false )
end

function Entity:toggleVisible()
	return self:setVisible( not self:isLocalVisible() )
end

function Entity:hideChildren()
	for child in pairs( self.children ) do
		child:hide()
	end
end

function Entity:showChildren()
	for child in pairs( self.children ) do
		child:show()
	end
end

--------------------------------------------------------------------
---Edit lock control
--------------------------------------------------------------------

function Entity:isLocalEditLocked()
	return self._editLocked
end

function Entity:setEditLocked( locked )
	self._editLocked = locked
end

function Entity:isEditLocked()
	if self._editLocked then return true end
	if self.parent then return self.parent:isEditLocked() end
	if self._entityGroup then return self._entityGroup:isEditLocked() end
	return false
end

--------------------------------------------------------------------
------Active control
--------------------------------------------------------------------
function Entity:start()
	if self.started then return end
	if not self.scene then return end
	
	if self.onStart then
		self:onStart()
	end
	self.started = true

	local copy = {} --there might be new components attached inside component starting
	for com in pairs( self.components ) do
		copy[ com ] = true
	end
	for com, clas in pairs( copy ) do
		local onStart = com.onStart
		if onStart then onStart( com, self ) end
	end

	for child in pairs( self.children ) do
		child:start()
	end

	if self.onThread then
		self:addCoroutine('onThread')		
	end
	
end

function Entity:setActive( active )	
	active = active or false
	if active == self.localActive then return end
	self.localActive = active
	self:_updateGlobalActive()
end

function Entity:_updateGlobalActive()
	local active = self.localActive
	local p = self.parent
	if p then
		active = p.active and active
		self.active = active
	else
		self.active = active
	end

	--inform components
	for com in pairs(self.components) do
		local setActive = com.setActive
		if setActive then
			setActive( com, active )
		end
	end

	--inform children
	for o in pairs(self.children) do
		o:_updateGlobalActive()
	end

	local onSetActive = self.onSetActive
	if onSetActive then
		return onSetActive( self, active )
	end
end

function Entity:isActive()
	return self.active
end

function Entity:isLocalActive()
	return self.localActive
end

function Entity:attachGlobalAction( groupId, action )
	return self.scene:attachGlobalAction( groupId, action )
end

function Entity:setActionPriority( action, priority )
	return self.scene:setActionPriority( action, priority )
end

function Entity:setCurrentCoroutinePriority( priority )
	local coro = self:getCurrentCoroutine()
	if coro then
		return self:setActionPriority( coro, priority )
	end
end

--------------------------------------------------------------------
------ Child/Component Method invoker
--------------------------------------------------------------------
function Entity:createTimer()
	local timers = self.timers
	if not timers then
		timers = {}
		self.timers = timers
	end

	local timer = self.scene:createTimer()
	timers[ timer ] = true
	timer:setListener( MOAIAction.EVENT_STOP, 
		function()
			timers[ timer ] = nil
		end
	)

	return timer
end

function Entity:invokeUpward( methodname, ... )
	local parent=self.parent
	
	if parent then
		local m=parent[methodname]
		if m and type(m)=='function' then return m( parent, ... ) end
		return parent:invokeUpward( methodname, ... )
	end

end

function Entity:invokeChildren( methodname, ... )
	for o in pairs(self.children) do
		o:invokeChildren( methodname, ... )
		local m=o[methodname]
		if m and type(m)=='function' then m( o, ... ) end
	end
end

function Entity:invokeComponents( methodname, ... )
	for com in pairs(self.components) do
		local m=com[methodname]
		if m and type(m)=='function' then m( com, ... ) end
	end
end

function Entity:invokeOneComponent( methodname, ... )
	for com in pairs(self.components) do
		local m=com[methodname]
		if m and type(m)=='function' then return m( com, ... ) end
	end
end

function Entity:tellSelfAndChildren( msg, data, source )
	self:tellChildren( msg, data, source )
	return self:tell( msg, data, source )
end

function Entity:tellChildren( msg, data, source )
	for ent in pairs( self.children ) do
		ent:tellChildren( msg, data, source )
		ent:tell( msg, data, source )
	end
end

function Entity:tellParent( msg, data, source )
	if not self.parent then return end
	return self.parent:tell( msg, data, source )
end

function Entity:tellSiblings( msg, data, source )
	if not self.parent then return end
	for ent in pairs( self.parent.children ) do
		if ent ~= self then
			return ent:tell( msg, data, source )
		end
	end
end

--------------------------------------------------------------------
--Function caller
--------------------------------------------------------------------
function Entity:callNextFrame(f, ... )
	if not self.scene then return end
	local t = { func = f, object = self, ... }
	insert( self.scene.pendingCall, t )
end

function Entity:callInterval( interval, func, ... )

	local timer = self:createTimer()
	local args

	if type( func ) == 'string' then
		func = self[func]
		args = { self, ... }
	else
		args = {...}
	end

	timer:setListener( MOAITimer.EVENT_TIMER_END_SPAN, 
		function()
			return func( unpack(args) )
		end
		)
	timer:setMode( MOAITimer.LOOP )
	timer:setSpan( interval )
	return timer
end

function Entity:callLater( time, func, ... )
	local timer = self:createTimer()
	local args

	if type( func ) == 'string' then
		func = self[func]
		args = { self, ... }
	else
		args = {...}
	end

	timer:setListener( MOAITimer.EVENT_TIMER_END_SPAN, 
		function()			
			return func( unpack(args) )
		end
		)
	timer:setMode( MOAITimer.NORMAL )
	timer:setSpan( time )
	return timer
end

local NewMOAIAction = MOAIAction.new
local EVENT_START = MOAIAction.EVENT_START
local EVENT_STOP  = MOAIAction.EVENT_STOP
function Entity:callAsAction( func )
	local action = NewMOAIAction()
	action:setListener( EVENT_STOP, func )
	return action
end

--------------------------------------------------------------------
--Color
--------------------------------------------------------------------
function Entity:getColor()
	return extractColor( self._prop )
end

function Entity:setColor( r,g,b,a )
	return self._prop:setColor( r,g,b,a )
end

--------------------------------------------------------------------
----------Transform Conversion
--------------------------------------------------------------------
function Entity:setWorldLoc( x,y,z )
	return self._prop:setWorldLoc( x, y, z )
end

function Entity:setWorldRot( dir )
	return self._prop:setWorldRot( dir )
end

function Entity:wndToWorld( x, y, z )
	return self.layer:wndToWorld( x, y, z )
end

function Entity:worldToWnd( x, y ,z )
	return self.layer:worldToWnd( x, y ,z )
end

function Entity:worldToProj( x, y ,z )
	return self.layer:worldToProj( x, y ,z )
end

function Entity:worldToView( x, y ,z )
	return self.layer:worldToView( x, y ,z )
end

function Entity:worldToModel( x, y ,z )
	return self._prop:worldToModel( x, y ,z )
end

function Entity:modelToWorld( x, y ,z )
	return self._prop:modelToWorld( x, y ,z )
end

function Entity:wndToModel( x, y, z )
	return self._prop:worldToModel( self.layer:wndToWorld( x, y, z ) )
end

function Entity:modelToWnd( x, y ,z )
	return self.layer:worldToWnd( self._prop:modelToWorld( x, y ,z ) )
end

function Entity:modelToProj( x, y ,z )
	return self.layer:worldToProj( self._prop:modelToWorld( x, y ,z ) )
end

function Entity:modelToView( x, y ,z )
	return self.layer:worldToView( self._prop:modelToWorld( x, y ,z ) )
end

function Entity:modelRectToWorld(x0,y0,x1,y1)
	x0,y0 = self:modelToWorld(x0,y0)
	x1,y1 = self:modelToWorld(x1,y1)
	return x0,y0,x1,y1
end

function Entity:worldRectToModel(x0,y0,x1,y1)
	x0,y0 = self:worldToModel(x0,y0)
	x1,y1 = self:worldToModel(x1,y1)
	return x0,y0,x1,y1
end

---------Scissor Rect?????
function Entity:_setScissorRect( rect )
	self.scissorRect = rect
	for com in pairs( self.components ) do
		local setScissorRect = com.setScissorRect
		if setScissorRect then
			setScissorRect( com, rect )
		end
	end
	for child in pairs( self.children ) do
		child:_setScissorRect( rect )
	end
	return rect
end

function Entity:setScissorRect( x1,y1,x2,y2, noFollow )
	local rect = nil
	if x1 then
		rect = self:makeScissorRect( x1,y1,x2,y2, noFollow )
	end
	return self:_setScissorRect( rect )
end

function Entity:makeScissorRect( x1, y1, x2, y2, noFollow )
	local rect = MOAIScissorRect.new()
	rect:setRect( x1, y2, x2, y1 )
	if not noFollow then self:_attachTransform( rect ) end
	return rect
end

--------------------------------------------------------------------
----------other prop wrapper
--------------------------------------------------------------------
function Entity:setupTransform( transform )
	return setupMoaiTransform( self._prop, transform )
end

function Entity:inside( x, y, z, pad, checkChildren )
	for com in pairs(self.components) do
		local inside = com.inside
		if inside then
			if inside( com, x, y, z, pad ) then return true end
		end
	end

	if checkChildren~=false then
		for child in pairs(self.children) do
			if child:inside(x,y,z,pad) then
				return true
			end
		end
	end
	
	return false
end

function Entity:pick( x, y, z, pad )
	if self.FLAG_EDITOR_OBJECT or self.FLAG_INTERNAL then return nil end
	for child in pairs(self.children) do
		local e = child:pick(x,y,z,pad)
		if e then return e end
	end

	for com in pairs(self.components) do
		local inside = com.inside
		if inside then
			if inside( com, x, y, z, pad ) then return self end
		end
	end
	
	return nil
end

local min = math.min
local max = math.max
function Entity:getBounds( reason )
	local bx0, by0, bz0, bx1, by1, bz1
	for com in pairs( self.components ) do
		local getBounds = com.getBounds
		if getBounds then
			local x0,y0,z0, x1,y1,z1 = getBounds( com, reason )
			if x0 then
				x0,y0,z0, x1,y1,z1 = x0 or 0,y0 or 0,z0 or 0, x1 or 0,y1 or 0,z1 or 0
				bx0 = bx0 and min( x0, bx0 ) or x0
				by0 = by0 and min( y0, by0 ) or y0
				bz0 = bz0 and min( z0, bz0 ) or z0
				bx1 = bx1 and max( x1, bx1 ) or x1
				by1 = by1 and max( y1, by1 ) or y1
				bz1 = bz1 and max( z1, bz1 ) or z1
			end
		end
	end
	return bx0 or 0, by0 or 0, bz0 or 0, bx1 or 0, by1 or 0, bz1 or 0
end

function Entity:resetTransform()
	self:setLoc( 0, 0, 0 )
	self:setRot( 0, 0, 0 )
	self:setScl( 1, 1, 1 )
	self:setPiv( 0, 0, 0 )
end

function Entity:setHexColor( hex, alpha )
	return self:setColor( hexcolor( hex, alpha ) )
end

function Entity:seekHexColor( hex, alpha, duration, easeType )
	local r,g,b = hexcolor( hex )
	return self:seekColor( r,g,b, alpha, duration ,easeType )
end

function Entity:getHexColor()
	local r,g,b,a = self:getColor() 
	local hex = colorhex( r,g,b )
	return hex, a
end
-- function Entity:onEditorPick( x, y, z, pad )
-- 	for child in pairs(self.children) do
-- 		local e = child:onEditorPick(x,y,z,pad)
-- 		if e then return e end
-- 	end

-- 	for com in pairs(self.components) do
-- 		local inside = com.inside
-- 		if inside then
-- 			if inside( com, x, y, z, pad ) then return self end
-- 		end
-- 	end
-- 	return nil
-- end


--------------------------------------------------------------------
--- Registry
--------------------------------------------------------------------

local entityTypeRegistry = {}
function registerEntity( name, creator )
	if not creator then
		return _error( 'no entity to register', name )
	end

	if not name then
		return _error( 'no entity name specified' )
	end
	-- assert( name and creator, 'nil name or entity creator' )
	-- assert( not entityTypeRegistry[ name ], 'duplicated entity type:'..name )
	_stat( 'register entity type', name )
	entityTypeRegistry[ name ] = creator

end

function getEntityRegistry()
	return entityTypeRegistry
end

function getEntityType( name )
	return entityTypeRegistry[ name ]
end

--------------------------------------------------------------------
registerEntity( 'Entity', Entity )


--------------------------------------------------------------------
--Serializer Related
--------------------------------------------------------------------
local function _cloneEntity( src, cloneComponents, cloneChildren, objMap, ensureComponentOrder )
	local objMap = {}
	local dst = clone( src, nil, objMap )
	dst.layer = src.layer
	if cloneComponents ~= false then
		if ensureComponentOrder then
			for i, com in ipairs( src:getSortedComponentList() ) do
				if not com.FLAG_INTERNAL then
					local com1 = clone( com, nil, objMap )
					dst:attach( com1 )
				end
			end
		else
			for com in pairs( src.components ) do
				if not com.FLAG_INTERNAL then
					local com1 = clone( com, nil, objMap )
					dst:attach( com1 )
				end
			end
		end
	end
	if cloneChildren ~= false then
		for child in pairs( src.children ) do
			if not child.FLAG_INTERNAL then
				local child1 = _cloneEntity( child, cloneComponents, cloneChildren, objMap, ensureComponentOrder )
				dst:addChild( child1 )
			end
		end
	end
	return dst
end

function cloneEntity( src, ensureComponentOrder )
	return _cloneEntity( src, true, true, nil, ensureComponentOrder )
end

