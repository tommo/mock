module 'mock'

local ATTR_LOCAL_VISIBLE= MOAIProp. ATTR_LOCAL_VISIBLE
local ATTR_VISIBLE      = MOAIProp. ATTR_VISIBLE
local INHERIT_VISIBLE   = MOAIProp. INHERIT_VISIBLE

CLASS: EntityGroup ()
	:MODEL{
		-- Field '__guid': string() :no_edit();

		Field 'name': string() :getset( 'Name' ) ;
		Field 'visible' :boolean() :get( 'isLocalVisible' ) :set( 'setVisible');
	}

function EntityGroup:__init()
	-- self.__guid = false
	self._prop = MOAIProp.new() --only control visiblity
	self._priority = 0
	self.scene  = false
	self.parent = false
	self.childGroups = {}
	self.entities     = {}
	self.name = 'EntityGroup'
	self.icon = false
end

function EntityGroup:getName()
	return self.name
end

function EntityGroup:setName( name )
	self.name = name
end

function EntityGroup:isVisible()
	return self._prop:getAttr( MOAIProp.ATTR_VISIBLE ) == 1
end

function EntityGroup:isLocalVisible()
	local vis = self._prop:getAttr( MOAIProp.ATTR_LOCAL_VISIBLE )
	return vis == 1
end

function EntityGroup:setVisible( visible )
	self._prop:setVisible( visible )
end

function EntityGroup:getName()
	return self.name
end

function EntityGroup:getIcon()
	return self.icon
end

function EntityGroup:addEntity( e )
	e:getProp( 'render' ):setAttrLink( INHERIT_VISIBLE, self._prop, ATTR_VISIBLE )
	e._entityGroup = self
	self.entities[ e ] = true
	assert( not e.parent )
	return e
end

function EntityGroup:removeEntity( e )
	e:getProp( 'render' ):clearAttrLink( INHERIT_VISIBLE )
	e._entityGroup = false
	self.entities[ e ] = nil
end

function EntityGroup:addChildGroup( g )
	g.parent = self
	g.scene  = self.scene
	g._prop:setAttrLink( INHERIT_VISIBLE, self._prop, ATTR_VISIBLE )
	self.childGroups[ g ] = true
	local entityListener = self.scene.entityListener
	if entityListener then entityListener( 'add_group', g, self.scene ) end
	return g
end

function EntityGroup:removeChildGroup( g )
	if g.parent == self then
		g._prop:setAttrLink( INHERIT_VISIBLE, self._prop, ATTR_VISIBLE )
		self.childGroups[ g ] = nil
		local entityListener = self.scene.entityListener
		if entityListener then entityListener( 'remove_group', g, self.scene ) end
	end
end

function EntityGroup:getChildGroups()
	return self.childGroups
end

function EntityGroup:getEntites()
	return self.entities
end

function EntityGroup:getParentOrGroup()
	return self.parent
end

function EntityGroup:addChild( entity )
	if isInstance( entity, Entity ) then
		self.scene:addEntity( entity, nil, self )
	elseif isInstance( entity, EntityGroup ) then
		self:addChildGroup( entity )
	end
end


function EntityGroup:_ungroupEntities( targetGroup )
	for childGroup in pairs( self.childGroups ) do
		childGroup:_ungroupEntities( targetGroup )
	end
	for ent in pairs( self.entities ) do
		targetGroup:addEntity( ent )
	end
end

function EntityGroup:reparent( targetGroup )
	if targetGroup == self.parent then return end
	self.parent:removeChildGroup( self )
	targetGroup:addChildGroup( self )
end

function EntityGroup:ungroup()
	assert( self.parent )
	self:_ungroupEntities( self.parent )
	self.parent:removeChildGroup( self )
end


function EntityGroup:destroyWithChildrenNow()
	for childGroup in pairs( self.childGroups ) do
		childGroup:destroyWithChildrenNow()
	end
	self.parent:removeChildGroup( self )
	for e in pairs( self.entities ) do
		e:destroyWithChildrenNow()
	end
	self.entities = {}
end


