module 'mock'

local _activeFocusManager = false

--------------------------------------------------------------------
CLASS: UIFocusManager ()
	:MODEL{}

function UIFocusManager:__init( view )
	self.view = view
	self.focusedWidget = false
	self.focusMap = false
	self.active = false
end

function UIFocusManager:activate()
	if _activeFocusManager == self then return end
	if _activeFocusManager then
		_activeFocusManager:deactivate( false )
	end
	--TODO: set focus to 'default focusable widget?'
	_activeFocusManager = self
	self.active = true
	self.view.focus_in:emit()
end

function UIFocusManager:deactivate()
	if _activeFocusManager ~= self then return end
	_activeFocusManager = false
	self:setFocusedWidget( false )
	self.active = false
	self.view.focus_out:emit()
end

function UIFocusManager:isActive()
	return _activeFocusManager == self
end

function UIFocusManager:setFocusedWidget( widget, reason )
	local previous = self.focusedWidget
	if previous == widget then return true end
	local view = self.view
	if previous then
		view:postEvent( previous, UIEvent( UIEvent.FOCUS_OUT ) )
	end
	if widget then
		self:activate()
		view:postEvent( widget, UIEvent( UIEvent.FOCUS_IN, { reason = reason } ) )
	end
	self.focusedWidget = widget or false
	return true
end

function UIFocusManager:getFocusedWidget()
	return self.focusedWidget
end

-- function UIFocusManager:getFirstFocusable()
-- 	--TODO
-- end

-- function UIFocusManager:getNextFocus( widget, dir, wrap ) -- N/S/E/W
-- 	--TODO
-- end

-- function UIFocusManager:moveFocus( dir ) -- N/S/E/W
-- 	local focused = self.focusedWidget
-- 	if not focused then return false end
-- 	local nextFocused = self:getNextFocus( focused, dir, wrap )
-- 	if not nextFocused then return false end
-- 	self:setFocusedWidget( nextFocused )
-- end
