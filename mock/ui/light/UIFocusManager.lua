module 'mock'

CLASS: UIFocusManager ()
	:MODEL{}

function UIFocusManager:__init( view )
	self.view = view
	self.focusedWidget = false
	self.focusMap = false
end

function UIFocusManager:getFocusedWidget()
	return self.focusedWidget
end

function UIFocusManager:getFirstFocusable()
	--TODO
end

function UIFocusManager:getNextFocus( widget, dir, wrap ) -- N/S/E/W
	--TODO
end

function UIFocusManager:moveFocus( dir ) -- N/S/E/W
	local focused = self.focusedWidget
	if not focused then return false end
	local nextFocused = self:getNextFocus( focused, dir, wrap )
	if not nextFocused then return false end
	self:setFocusedWidget( nextFocused )
end
