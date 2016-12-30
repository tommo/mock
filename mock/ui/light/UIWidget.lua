module 'mock'

local insert, remove = table.insert, table.remove
--------------------------------------------------------------------
local function widgetZSortFunc( w1, w2 )
	local z1 = w1:getLocZ()
	local z2 = w2:getLocZ()
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
end

function UIWidgetBase:getStyleSheetObject()
	local localStyleSheet = self.localStyleSheet
	if localStyleSheet then return localStyleSheet end
	local p = self.parent
	if p and p.FLAG_UI_WIDGET then
		return p:getStyleSheetObject()
	end
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


--------------------------------------------------------------------
CLASS: UIWidget ( UIWidgetBase )
	:MODEL{
		--- hide common entity properties
			Field '__gizmoIcon' :no_edit();
			Field 'color' :type('color') :no_edit();
			Field 'rot'   :no_edit();
			Field 'scl'   :no_edit();
			Field 'piv'   :no_edit();
			Field 'layer' :no_edit();
		--------
		Field 'loc'  :type( 'vec2' ) :meta{ decimals = 0 } :getset( 'Loc'  ) :label( 'Loc'  );
		Field 'size' :type( 'vec2' ) :meta{ decimals = 0 } :getset( 'Size' ) :label( 'Size' );
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
end

function UIWidget:getParentWidget()
	local p = self.parent
	if not p then return false end
	if not p.FLAG_UI_WIDGET then return false end
	if p:isRootWidget() then return false end
	return true
end

function UIWidget:onLoad()
	self:initContent()
	self:onInitContent()
	self:invalidateStyle()
	self:updateVisual()
end

function UIWidget:destroyNow()
	if self._parentView then
		self._parentView:onWidgetDestroyed( self )
	end
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

function UIWidget:removeFeature( feature )
	return self:setFeature( feature, false )
end

function UIWidget:toggleFeature( feature )
	return self:setFeature( feature, not self:hasFeature( feature ) )
end

function UIWidget:invalidateStyle()
	local view = self:getParentView()
	if view then
		view:scheduleVisualUpdate( self )
	end
end

function UIWidget:updateVisual()
	local style = self.styleAcc
	style:update()
	return self:onUpdateVisual( style )
end

function UIWidget:onUpdateVisual( style )
end

function UIWidget:initContent()
end

function UIWidget:onInitContent()
end


--------------------------------------------------------------------
--geometry
function UIWidget:onRectChange()
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

function UIWidget:setSize( w, h )
	if not w then
		w, h = self:getDefaultSize()
	end
	self.w, self.h = w, h
	self:getProp():setBounds( 0,0,0, w,h,0 )
	--todo: update layout in the root widget
	-- self:updateLayout()
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

function UIWidget:getRect()
	local w, h = self:getSize()
	return 0,0,w,h
end

function UIWidget:getContentRect()
	return self:getRect()
end

function UIWidget:getTouchPadding()
	return DEFAULT_TOUCH_PADDING
end

--------------------------------------------------------------------
--layout
function UIWidget:setLayout( l )
	if l then
		assert( not l.widget )
		self.layout = l
		l.widget = self
		self:updateLayout()
		return l
	else
		self.layout = false
	end
end

function UIWidget:invalidateLayout()
	local view = self:getParentView()
	if view then
		view:scheduleLayoutUpdate( self )
	end
end

-- function UIWidget:updateLayout()
-- 	if self.layout then
-- 		self.layout:onLayout( self )
-- 	end
-- end
--------------------------------------------------------------------
--size hints
function UIWidget:getDefaultSize()
	local default = self.overridedSize.default
	if default then
		return unpack( default )
	else
		return self:getDefaultSizeHint()
	end
end

function UIWidget:getDefaultSizeHint()
	return 0, 0
end

function UIWidget:getMinSize()
	local min = self.overridedSize.min
	if min then
		return unpack( min )
	else
		return self:getMinSizeHint()
	end
end

function UIWidget:getMinSizeHint()
	return 0,0
end

function UIWidget:getMaxSize()
	local max = self.overridedSize.max
	if max then
		return unpack( max )
	else
		return self:getMaxSizeHint()
	end
end

function UIWidget:getMaxSizeHint()
	return 1000, 1000
end

--------------------------------------------------------------------
function UIWidget:setInputEnabled( enabled )
	self.inputEnabled = enabled ~= false
end

--------------------------------------------------------------------
function UIWidget:onSizeHint()
	return 0, 0
end

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
--editor
function UIWidget:onBuildGizmo(  )
	return mock_edit.SimpleBoundGizmo()	
end

function UIWidget:drawBounds()
	GIIHelper.setVertexTransform( self:getProp() )
	-- local x1,y1,z1, x2,y2,z2 = self.prop:getBounds()
	-- MOAIDraw.drawRect( x1,y1,x2,y2 )
	local w, h = self:getSize()
	MOAIDraw.drawRect( 0, 0, w, h )
end

