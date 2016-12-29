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
CLASS: UIWidget ( Entity )
	:MODEL{
		--- hide common entity properties
			Field 'color' :type('color') :no_edit();
			Field 'rot'   :no_edit();
			Field 'scl'   :no_edit();
			Field 'piv'   :no_edit();
			Field 'layer' :no_edit();
		--------
		--------
		Field 'loc'  :type( 'vec2' ) :meta{ decimals = 0 } :getset( 'Loc'  ) :label( 'Loc'  );
		Field 'size' :type( 'vec2' ) :meta{ decimals = 0 } :getset( 'Size' ) :label( 'Size' );
	}
	:META{
		category = 'UI'
	}

--------------------------------------------------------------------
----
function UIWidget:__init()
	self.FLAG_UI_WIDGET = true
	self.childWidgets   = {}

	self.styleAcc = UIStyleAccessor( self )

	self.w = 100
	self.h = 100
	self.overridedSize = {}
	
	self.focusPolicy = 'normal'
	self.clippingChildren = false

	self.layout = false
	self.skin   = false
end

--------------------------------------------------------------------
function UIWidget:sendEvent( ev )
	self:procEvent( ev )
	if not ev.accepted then
		local parent = self.parent
		if parent and parent.FLAG_UI_WIDGET then
			return parent:sendEvent( ev )
		end
	end
end

function UIWidget:procEvent( ev )
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

function UIWidget:onStyleChanged()
end

--------------------------------------------------------------------
function UIWidget:setSkin( skinPath )
	self.skinPath = skinPath
	local skin = loadAsset( skinPath )
	self.skin = skin or false
	self.styleAcc:setSkin( self.skin )
end

function UIWidget:getSkin()
	return self.skinPath
end


--------------------------------------------------------------------
function UIWidget:setClippingChildren( clipping )
	self.clippingChildren = clipping
end

function UIWidget:setFocusPolicy( policy )
	self.focusPolicy = policy or 'normal'
end

function UIWidget:onRectChange()
end

function UIWidget:_setParentView( v )
	self._parentView = v
end

function UIWidget:getParentView()
	return self._parentView
end

function UIWidget:_attachChildEntity( entity, layerName )
	if entity.FLAG_UI_WIDGET then		
		table.insert( self.childWidgets, entity )
		if self._parentView then
			entity:_setParentView( self._parentView )
		end
		self:sortChildren()
	end	
	return UIWidget.__super._attachChildEntity( self, entity, layerName )	
end

function UIWidget:_detachChildEntity( entity )
	if entity.FLAG_UI_WIDGET then
		local idx = table.index( self.childWidgets, entity )
		if idx then
			table.remove( self.childWidgets, idx )
		end
	end	
	return UIWidget.__super._detachChildEntity( self, entity )	
end

function UIWidget:sortChildren()
	table.sort( self.childWidgets, widgetZSortFunc )	
end

function UIWidget:destroyNow()
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
	if self.__modal then
		self:setModal( false )		
	end
	return UIWidget.__super.destroyNow( self )
end

function UIWidget:setModal( modal )
	modal = modal~=false
	if self.__modal == modal then return end
	self.__modal = modal
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

--geometry
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

function UIWidget:updateLayout()
	if self.layout then
		self.layout:onLayout( self )
	end
end

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
function UIWidget:onUpdateContent()
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

