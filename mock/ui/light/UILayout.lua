module 'mock'

CLASS: UILayout ()
	:MODEL{}

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

function UILayout:update()
	self.updating = true
	self:onUpdate()
	self.updating = false
end

function UILayout:onUpdate()
end
