module 'mock'
--------------------------------------------------------------------
CLASS: UIPointer ()
function UIPointer:__init()
	self.state        = 'up'
	self.activeWidget = false
	self.hoverWidget  = false
	self.touch        = false
end

function UIPointer:getTouch()
	return self.touch
end