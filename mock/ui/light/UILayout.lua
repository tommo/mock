module 'mock'

CLASS: UILayout ( Component )
	:MODEL{
		Field 'margin' :type('vec4') :getset( 'Margin' );
	}
	:META{
		category = 'UI'
	}

function UILayout:__init( widget )
	self.margin = { 10,10,10,10 }

	self.owner = false
	if widget then
		widget:setLayout( self )
	end
end

function UILayout:setOwner( owner )
	if self.owner == owner then return end
	assert( not self.owner )
	self.owner = owner
end

function UILayout:getOwner()
	return self.owner
end

function UILayout:getMargin()
	return unpack( self.margin )
end

function UILayout:getAvailableSize()
	local w, h = self:getOwner():getSize()
	local marginL, marginT, marginR, marginB = self:getMargin()
	w  = w - marginL - marginR
	h  = h - marginT - marginB
	return w, h
end

function UILayout:getMinAvailableSize()
	local w, h = self:getOwner():getMinSize()
	local marginL, marginT, marginR, marginB = self:getMargin()
	w  = w - marginL - marginR
	h  = h - marginT - marginB
	return w, h
end


function UILayout:getMaxAvailableSize()
	local w, h = self:getOwner():getMaxSize()
	local marginL, marginT, marginR, marginB = self:getMargin()
	if w < 0 then w = -1 else w  = w - marginL - marginR end
	if h < 0 then h = -1 else h  = h - marginT - marginB end
	return w, h
end

function UILayout:setMargin( left, top, right, bottom )
	self.margin = { left or 0, top or 0, right or 0, bottom or 0 }
	self:invalidate()
end


function UILayout:invalidate()
	local owner = self:getOwner()
	if owner then
		return owner:invalidateLayout()
	end
end

function UILayout:update()
	self.updating = true
	self:onUpdate()
	self.updating = false
end

function UILayout:onUpdate()
end


function UILayout:onAttach( ent )
	if not ent:isInstance( UIWidget ) then
		_warn( 'UILayout should be attached to UIWidget' )
		return false
	end
	local widget = ent
	widget:setLayout( self )
end

function UILayout:onDetach( ent )
	if not ent:isInstance( UIWidget ) then return end
	local widget = ent
	self.owner = false
	widget:setLayout( false )
end
