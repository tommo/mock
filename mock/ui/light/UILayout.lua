module 'mock'

CLASS: UILayout ( Component )
	:MODEL{}
	:META{
		category = 'UI'
	}

function UILayout:__init( widget )
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
