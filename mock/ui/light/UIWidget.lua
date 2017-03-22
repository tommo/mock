module 'mock'

local insert, remove = table.insert, table.remove

--------------------------------------------------------------------
local function widgetZSortFunc( w1, w2 )
	local z1 = w1.zorder
	local z2 = w2.zorder
	return z1 < z2
end

local function _updateRectCallback( node )
	return node.__src:onRectChange()
end

local function makeRectNode( src )
	local node = MOAIScriptNode.new()
	node.__src = src
	node:reserveAttrs( 4 )
	node:setCallback( _updateRectCallback )
	return node
end

--------------------------------------------------------------------
--------------------------------------------------------------------
CLASS: UIWidgetBase ( Entity )
	:MODEL{
		Field 'style' :asset_pre( 'ui_style' ) :getset( 'LocalStyleSheet' );
	}
	:META{
		category = 'UI'
	}

function UIWidgetBase:__init()
	self.FLAG_UI_WIDGET = true
	self.childWidgets   = {}
	self.localStyleSheetPath = false
	self.localStyleSheet = false
	self.zorder = 0
end

function UIWidgetBase:isRootWidget()
	return false
end

function UIWidgetBase:getLocalStyleSheet()
	return self.localStyleSheetPath
end

function UIWidgetBase:setLocalStyleSheet( path )
	self.localStyleSheetPath = path
	self.localStyleSheet = path and loadAsset( path )
	self:onLocalStyleSheetChanged()
end

function UIWidgetBase:getStyleSheetObject()
	local localStyleSheet = self.localStyleSheet
	if localStyleSheet then return localStyleSheet end
	local p = self.parent
	if p and p.FLAG_UI_WIDGET then
		return p:getStyleSheetObject()
	end
end

function UIWidgetBase:onLocalStyleSheetChanged()
end

function UIWidgetBase:_setParentView( v )
	self._parentView = v
end

function UIWidgetBase:getParentView()
	return self._parentView
end

function UIWidgetBase:_attachChildEntity( entity, layerName )
	if entity.FLAG_UI_WIDGET then		
		table.insert( self.childWidgets, entity )
		if self._parentView then
			entity:_setParentView( self._parentView )
		end
		self:sortChildren()
	end	
	return UIWidgetBase.__super._attachChildEntity( self, entity, layerName )	
end

function UIWidgetBase:_detachChildEntity( entity )
	if entity.FLAG_UI_WIDGET then
		local idx = table.index( self.childWidgets, entity )
		if idx then
			table.remove( self.childWidgets, idx )
		end
	end	
	return UIWidgetBase.__super._detachChildEntity( self, entity )	
end

function UIWidgetBase:sortChildren()
	table.sort( self.childWidgets, widgetZSortFunc )	
end

function UIWidgetBase:getZOrder()
	return self.zorder
end

function UIWidgetBase:setZOrder( z )
	self.zorder = z
	self:setLocZ( z )
	local p = self.parent
	if p and p.FLAG_UI_WIDGET then
		return p:sortChildren()
	end
end


--------------------------------------------------------------------
--------------------------------------------------------------------
CLASS: UIWidget ( UIWidgetBase )
	:MODEL{
		--- hide common entity properties
			Field '__gizmoIcon' :no_edit();
			Field 'rot'   :no_edit();
			Field 'scl'   :no_edit();
			Field 'piv'   :no_edit();
			Field 'layer' :no_edit();
		--------
		Field 'loc'  :type( 'vec2' ) :meta{ decimals = 0 } :getset( 'Loc'  ) :label( 'Loc'  );
		Field 'size' :type( 'vec2' ) :meta{ decimals = 0 } :getset( 'Size' ) :label( 'Size' );
		Field 'ZOrder' :int()  :getset( 'ZOrder' ) :label( 'Z-Order' );
		'----';
		Field 'layoutDisabled' :boolean() :label( 'Disable Layout' );
		Field 'layoutProportion' :type( 'vec2' ) :meta{ decimals = 0 } :getset( 'LayoutProportion' ) :label( 'Proportion' );
		'----';
	}

--------------------------------------------------------------------
function UIWidget:__init()
	self.styleAcc = UIStyleAccessor( self )


	self.w = 100
	self.h = 100
	self.overridedSize = {}
	
	self.focusPolicy = 'normal'
	self.clippingChildren = false

	self.layout = false
	self.localStyleSheetPath    = false

	self.inputEnabled = true
	self.eventFilters = {}

	self.layoutDisabled = false
	self.subWidget = false

	self.layoutPolicy     = { 'expand', 'expand' }
	self.layoutProportion = { 0, 0 }
	self.layoutAlignment  = { 'left', 'top' }

	self.renderers = {}
	self.contentModified = true
	self.styleModified = true
end

function UIWidget:initRenderers()
	self:addRenderer( UICommonStyleWidgetRenderer() )
end

function UIWidget:insertRenderer( idx, renderer, option )
	if not idx then
		table.insert( self.renderers, renderer )
	else
		table.insert( self.renderers, idx, renderer )
	end
	renderer:setWidget( self )
	renderer:setOptions( option or {} )
	if self.scene then
		renderer:onInit( self )
	end
	self:invalidateStyle()
	self:invalidateLayout()
	return renderer
end

function UIWidget:addRenderer( renderer, option )
	return self:insertRenderer( nil, renderer, option )
end

function UIWidget:removeRenderer( renderer )
	local idx = table.index( self.renderers, renderer )
	if idx then
		if self.scene then
			renderer:onDestroy( self )
		end
		table.remove( self.renderers, idx )
	end
end

function UIWidget:clearRenderers()
	if self.scene then
		local renderers = self.renderers
		for i, r in ipairs( renderers ) do
			r:onDestroy( self )
		end
	end
	self.renderers = {}
end

function UIWidget:setVisible( visible )
	local parent = self:getParentWidget()
	if parent then
		parent:invalidateLayout()
	end
	return UIWidget.__super.setVisible( self, visible )
end

function UIWidget:_attachChildEntity( entity, layerName )
	self:invalidateLayout()
	return UIWidget.__super._attachChildEntity( self, entity, layerName )	
end

function UIWidget:_detachChildEntity( entity )
	self:invalidateLayout()
	return UIWidget.__super._detachChildEntity( self, entity )	
end

function UIWidget:setZOrder( z )
	UIWidget.__super.setZOrder( self, z )
	return self:invalidateLayout()
end

function UIWidget:isSubWidget()
	return self.subWidget
end

function UIWidget:setSubWidget( subWidget )
	self.subWidget = subWidget and true or false
	self:invalidateVisual()
end

function UIWidget:getParentWidget()
	local p = self.parent
	if not p then return false end
	if not p.FLAG_UI_WIDGET then return false end
	if p:isRootWidget() then return false end
	return p
end

function UIWidget:getChildWidgets()
	return self.childWidgets
end

function UIWidget:getLayoutInfo()
	local minWidth, minHeight      = self:getMinSize()
	local maxWidth, maxHeight      = self:getMaxSize()
	local policyH, policyV         = self:getLayoutPolicy()
	local alignH, alignV           = self:getLayoutAlignment()
	local proportionH, proportionV = self:getLayoutProportion()
	return {
		widget      = self,
		minWidth    = minWidth,
		minHeight   = minHeight,
		maxWidth    = maxWidth,
		maxHeight   = maxHeight,
		policyH     = policyH,
		policyV     = policyV,
		proportionH = proportionH,
		proportionV = proportionV,
	}
end


function UIWidget:onLoad()
	self:initRenderers()
	for i, renderer in ipairs( self.renderers ) do
		renderer:onInit( self )
	end
end

function UIWidget:destroyNow()
	if self._parentView then
		self._parentView:onWidgetDestroyed( self )
	end
	self:clearRenderers()
	local parent = self.parent
	local childWidgets = parent and parent.childWidgets
	if childWidgets then
		for i, child in ipairs( childWidgets ) do
			if child == self then
				table.remove( childWidgets, i )
				break
			end
		end
	end
	if self._modal then
		self:setModal( false )		
	end
	return UIWidget.__super.destroyNow( self )
end


function UIWidget:setClippingChildren( clipping )
	self.clippingChildren = clipping
end

--------------------------------------------------------------------
function UIWidget:postEvent( ev )
	local view = self._parentView
	if not view then return false end
	view:postEvent( self, ev )
end

function UIWidget:sendEvent( ev )
	local needProc = true
	for i, filter in ipairs( self.eventFilters ) do 
		if filter( ev ) == false then 
			needProc = false
			break
		end
	end
	
	if needProc then
		self:procEvent( ev )
		self:onEvent( ev )
	end

	if not ev.accepted then
		local parent = self.parent
		if parent and parent.FLAG_UI_WIDGET and ( not parent:isRootWidget() ) then
			return parent:sendEvent( ev )
		end
	end
end

function UIWidget:procEvent( ev )
end

function UIWidget:onEvent( ev )
end

function UIWidget:addEventFilter( filter )
	if not type( filter ) == 'function' then return end
	local idx = table.index( self.eventFilters, 1, filter )
	if not idx then table.insert( self.eventFilters, filter ) end
end

function UIWidget:removeEventFilter( filter )
	local idx = table.index( self.eventFilters, filter )
	if idx then table.remove( self.eventFilters, idx ) end
end

--------------------------------------------------------------------
--Focus control
function UIWidget:hasFocus()
	local focused = self._parentView:getFocusedWidget()
	return focused == self
end

function UIWidget:isHovered()
	--==TODO
end

function UIWidget:hasChildFocus()
	if self:hasFocus() then return true end
	for i, child in ipairs( self.childWidgets	) do
		if child:hasChildFocus() then return true end
	end
	return false
end

function UIWidget:setFocus( reason )
	local view = self._parentView
	return view:setFocusedWidget( self, reason )
end

function UIWidget:setFocusPolicy( policy )
	self.focusPolicy = policy or 'normal'
end

function UIWidget:setModal( modal )
	modal = modal ~= false
	if self._modal == modal then return end
	self._modal = modal
	if self._parentView then
		if modal then 
			self._parentView:setModalWidget( self )
		else
			if self._parentView:getModalWidget() == self then
				self._parentView:setModalWidget( nil )
			end
		end
	end
end

--------------------------------------------------------------------
function UIWidget:getContentData( key, role )
	return nil
end


--------------------------------------------------------------------
function UIWidget:getFeatures()
	return self.styleAcc.features
end

function UIWidget:setFeatures( features )
	return self.styleAcc:setFeatures( features )
end

function UIWidget:clearFeatures()
	self.styleAcc:setFeatures( false )
end

function UIWidget:hasFeature( feature )
	return self.styleAcc:hasFeature( feature )
end

function UIWidget:setFeature( feature, bvalue )
	return self.styleAcc:setFeature( feature, bvalue ~= false )
end

function UIWidget:addFeature( feature )
	return self:setFeature( feature, true )
end

function UIWidget:removeFeature( feature )
	return self:setFeature( feature, false )
end

function UIWidget:toggleFeature( feature )
	return self:setFeature( feature, not self:hasFeature( feature ) )
end

function UIWidget:invalidateContent()
	self.contentModified = true
	self:invalidateVisual()
end

function UIWidget:invalidateVisual()
	local view = self:getParentView()
	if view then
		view:scheduleVisualUpdate( self )
	end
end

function UIWidget:invalidateStyle()
	self.styleAcc:markDirty()
end

function UIWidget:updateVisual()
	local style = self.styleAcc
	style:update()
	local contentModified = self.contentModified
	local styleModified = self.styleModified
	self.contentModified = false
	self.styleModified = false
	for i, r in ipairs( self.renderers ) do
		r:update( self, style, styleModified, contentModified )
	end
end

function UIWidget:onUpdateVisual( style )
end


--------------------------------------------------------------------
--geometry
function UIWidget:getViewLoc()
	local wx, wy, wz = self:getWorldLoc()
	local view = self:getParentView()
	if view then
		return view:worldToModel( wx, wy, wz )
	else
		return wx, wy, wz
	end
end

function UIWidget:inside( x, y, z, pad )
	x,y = self:worldToModel( x, y )
	local x0,y0,x1,y1 = self:getRect()
	if x0 > x1 then x1,x0 = x0,x1 end
	if y0 > y1 then y1,y0 = y0,y1 end
	if pad then
		return x >= x0-pad and x <= x1+pad and y >= y0-pad and y<=y1+pad
	else
		return x >= x0 and x <= x1 and y >= y0 and y <= y1
	end
end

function UIWidget:setSize( w, h, updateLayout, updateStyle )
	w, h = w or self.w, h or self.h
	self.w, self.h = w, h
	self:getProp():setBounds( 0,0, w, h )
	if updateLayout ~= false then
		self:invalidateLayout()
	end
	
	if updateStyle ~= false then
		self:invalidateVisual()
	end
end

function UIWidget:getSize()
	return self.w, self.h
end

function UIWidget:setRect( x, y, w, h )
	self.x = x
	self.y = y
	self.w = w
	self.h = h
end

function UIWidget:getLocalRect()
	local w, h = self:getSize()
	return 0, 0, w, h
end

function UIWidget:getLocalRectCenter()
	local x0, y0, x1, y1 = self:getLocalRect()
	return ( x0 + x1 )/2, ( y0 + y1 )/2
end

function UIWidget:getRect()
	local w, h = self:getSize()
	return 0,0,w,h
end

function UIWidget:getContentRect()
	return self:getRect()
end

--------------------------------------------------------------------
--layout
function UIWidget:setLayout( l )
	if l then
		assert( not l.widget )
		self.layout = l
		l:setOwner( self )
		self:invalidateLayout()
		return l
	else
		self.layout = false
	end
end

function UIWidget:invalidateLayout()
	local view = self:getParentView()
	if view then
		local p = self
		while p do
			view:scheduleLayoutUpdate( p )
			p = p:getParentWidget()
		end
	end
end

function UIWidget:updateLayout()
	local layout = self.layout 
	if not layout then return end
	layout:update()
	self:invalidateVisual()
end

function UIWidget:getLayoutPolicy()
	return unpack( self.layoutPolicy )
end

function UIWidget:setLayoutPolicy( h, v )
	self.layoutPolicy = { h, v }
	self:invalidateLayout()
end

function UIWidget:getLayoutAlignment()
	return unpack( self.layoutAlignment )
end

function UIWidget:setLayoutAlignment( h, v )
	self.layoutAlignment = { h, v }
	self:invalidateLayout()
end

function UIWidget:getLayoutProportion()
	return unpack( self.layoutProportion )
end

function UIWidget:setLayoutProportion( h, v )
	self.layoutProportion = { h, v }
	self:invalidateLayout()
end


function UIWidget:getLayoutableChildInfo()
	local result = {}
	for i, widget in ipairs( self.childWidgets ) do
		if ( not widget.layoutDisabled ) and widget:isVisible() then
			local entry = widget:getLayoutInfo()
			insert( result, entry )
		end
	end
	return result
end

--------------------------------------------------------------------

function UIWidget:getMinSizeHint()
	return 0,0
end

function UIWidget:getMaxSizeHint()
	return -1,-1
end

function UIWidget:getMinSize()
	local min = self.overridedSize.min
	if min then
		return unpack( min )
	else
		return self:getMinSizeHint()
	end
end

function UIWidget:getMaxSize()
	local overridedSize = self.overridedSize
	local max = self.overridedSize.max
	if max then
		return unpack( max )
	else
		return self:getMaxSizeHint()
	end
end

function UIWidget:getWidth()
	local w, h = self:getSize()
	return w
end

function UIWidget:getHeight()
	local w, h = self:getSize()
	return h
end

function UIWidget:getMaxWidth()
	local w, h = self:getMaxSize()
	return w
end

function UIWidget:getMaxHeight()
	local w, h = self:getMaxSize()
	return h
end

function UIWidget:getMinWidth()
	local w, h = self:getMinSize()
	return w
end

function UIWidget:getMinHeight()
	local w, h = self:getMinSize()
	return h
end
--------------------------------------------------------------------
function UIWidget:setInputEnabled( enabled )
	self.inputEnabled = enabled ~= false
end

--------------------------------------------------------------------
function UIWidget:onSetActive( active )
	self:setState( active and 'normal' or 'disabled' )	
end

function UIWidget:setState( state )
	local ps = self.state
	if state ~= ps then
		--change state
		self.styleAcc:setState( state )
	end
	return UIWidget.__super.setState( self, state )
end

--------------------------------------------------------------------
--extra
function UIWidget:getTouchPadding()
	return DEFAULT_TOUCH_PADDING
end

--------------------------------------------------------------------
--editor
function UIWidget:onBuildGizmo( )
	return mock_edit.DrawScriptGizmo()	
end

function UIWidget:onDrawGizmo( selected )
	GIIHelper.setVertexTransform( self:getProp() )
	MOAIGfxDevice.setPenColor( hexcolor('#fc0bff', selected and 0.9 or 0.4 ) )
	local w, h = self:getSize()
	MOAIDraw.drawRect( 0, 0, w, h )
end
