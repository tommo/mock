module 'mock'

CLASS: TBWidget ( Entity )
	:MODEL{
		Field 'color' :type('color') :no_edit();
		Field 'rot' :no_edit();
		Field 'scl' :no_edit();
		Field 'piv' :no_edit();
		Field 'layer' :no_edit();
		----

		Field 'loc' :type( 'vec2' ) :meta{ decimals = 0 } :getset( 'Loc') :label( 'Loc');
		Field 'size' :type( 'vec2' ) :meta{ decimals = 0 } :getset( 'Size') :label( 'Size');
		Field 'opacity';
		Field 'skin' :asset( 'tb_skin' );
		Field 'skinClass' :string(); --:selection( getSkinClassSelection )
		'----';
	}

function TBWidget:__init()
	self.__TBWIDGET = true

	self.skin = false
	self.skinClass = ''
	self.opacity = 1.0

	self:affirmInternalWidget()
end

function TBWidget:getLoc()
	local x, y = self:getProp():getLoc()
	return x, y
end

function TBWidget:setLoc( x, y )
	return self:getProp():setLoc( x, y )
end

function TBWidget:getSize()
	return self:getInternalWidget():getSize()
end

function TBWidget:setSize( w, h )
	return self:getInternalWidget():setSize( w, h )
end

function TBWidget:_attachChildEntity( entity )
	if entity.__TBWIDGET then
		return self:attachChildWidget( entity, layerName )
	end	
	return TBWidget.__super._attachChildEntity( entity )
end

function TBWidget:_detachChildEntity( entity )
	if entity.__TBWIDGET then
		return self:detachChildWidget( entity, layerName )
	end	
	return TBWidget.__super._detachChildEntity( entity )
end

function TBWidget:attachChildWidget( widget )
	self:getInternalWidget():getContentRoot():addChild( widget:getInternalWidget() )
	self:_attachLoc( widget:getProp() )
	self:refreshCanvas()
end

function TBWidget:detachChildWidget( widget )
	self:getInternalWidget():removeChild( widget:getInternalWidget() )
	local _p1   = widget._prop
	clearInheritTransform( _p1 )
	self:refreshCanvas()
end


function TBWidget:onDestroy()
	local internal = self:getInternalWidget()
	if internal then
		local parent = internal:getParent()
		if parent then
			parent:removeChild( internal )
		end
	end
end

function TBWidget:getInternalWidget()
	return self.internalWidget
end

function TBWidget:affirmInternalWidget()
	if self.internalWidget then return self.internalWidget end
	self.internalWidget = self:createInternalWidget()
	local prop = self._prop
	self.internalWidget:setAttrLink( MOAITBWidget.ATTR_X_LOC, prop, MOAIProp.ATTR_X_LOC )
	self.internalWidget:setAttrLink( MOAITBWidget.ATTR_Y_LOC, prop, MOAIProp.ATTR_Y_LOC )
	return self.internalWidget
end

function TBWidget:getSkinClassSelection()
	--TODO
end

function TBWidget:createInternalWidget()
	return MOAITBWidget.new()
end

function TBWidget:getCanvas()
	local p = self.parent
	while p do
		if p:isInstance( TBCanvas ) then return p end
		if p:isInstance( TBWidget ) then
			p = p.parent
		else
			return nil
		end
	end

end

function TBWidget:refreshCanvas()
	local canvas = self:getCanvas()
	if canvas then return canvas:refresh() end
end

function TBWidget:setWorldLoc( x, y, z )
	local x, y = self:getCanvas():worldToModel( x, y )
	self:setCanvasLoc( x, y )
end

function TBWidget:getCanvasLoc()
	local x, y = self:getLoc()
	local p = self.parent
	while p do
		if not p.__TBWIDGET then break end
		local xx, yy = p:getLoc()
		x = x + xx
		y = y + yy
	end
	return x, y
end

function TBWidget:setCanvasLoc( x, y )
	local parent = self.parent
	if parent.__TBWIDGET then
		local cx, cy = parent:getCanvasLoc()
		return self:setLoc( x-cx, y-cy )
	else
		return self:setLoc( x, y )
	end
end

--FIXME:...
function TBWidget:_createTransformProxy()
	return mock_edit.TBWidgetTransformProxy()
end