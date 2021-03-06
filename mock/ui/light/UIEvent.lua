module 'mock'

--------------------------------------------------------------------
CLASS: UIEvent ()
	:MODEL{}

function UIEvent:__init( type, data )
	self.type = assert( type, 'nil event type' )
	self.data = data
	self.accepted = false
end

function UIEvent:accept()
	self.accepted = true
end

function UIEvent:ignore()
	self.accepted = false
end

--------------------------------------------------------------------

--INPUT
UIEvent.POINTER_DOWN  = "pointerDown"
UIEvent.POINTER_UP    = "pointerUp"
UIEvent.POINTER_MOVE  = "pointerMove"
UIEvent.POINTER_SCROLL = "pointerScroll"

UIEvent.POINTER_ENTER = "pointerEnter"
UIEvent.POINTER_EXIT  = "pointerExit"

UIEvent.JOYSTICK_BUTTON_DOWN  = "joystickButtonDown"
UIEvent.JOYSTICK_BUTTON_UP  = "joystickButtonUp"
UIEvent.JOYSTICK_AXIS_MOVE  = "joystickAxisMove"

UIEvent.KEY_DOWN  = "keyDown"
UIEvent.KEY_UP  = "keyUp"


UIEvent.RESIZE        = "resize"
UIEvent.SKIN_CHANGED  = "themeChanged"
UIEvent.STYLE_CHANGED = "styleChanged"
UIEvent.FOCUS_IN      = "focusIn"
UIEvent.FOCUS_OUT     = "focusOut"
UIEvent.VIEW_FOCUS_IN = "viewFocusIn"
UIEvent.VIEW_FOCUS_OUT= "viewFocusOut"
UIEvent.CLICK         = "click"
UIEvent.CANCEL        = "cancel"
UIEvent.DOWN          = "down"
UIEvent.UP            = "up"
UIEvent.VALUE_CHANGED = "valueChanged"
UIEvent.STICK_CHANGED = "stickChanged"
UIEvent.MSG_SHOW      = "msgShow"
UIEvent.MSG_HIDE      = "msgHide"
UIEvent.MSG_END       = "msgEnd"
UIEvent.SPOOL_STOP    = "spoolStop"
UIEvent.ITEM_CHANGED  = "itemChanged"
UIEvent.ITEM_ENTER    = "itemEnter"
UIEvent.ITEM_CLICK    = "itemClick"
UIEvent.SCROLL        = "scroll"
