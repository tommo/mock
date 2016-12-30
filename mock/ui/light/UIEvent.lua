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
UIEvent.TOUCH_DOWN    = "touchDown"
UIEvent.TOUCH_UP      = "touchUp"
UIEvent.TOUCH_MOVE    = "touchMove"

UIEvent.RESIZE        = "resize"
UIEvent.SKIN_CHANGED  = "themeChanged"
UIEvent.STYLE_CHANGED = "styleChanged"
UIEvent.FOCUS_IN      = "focusIn"
UIEvent.FOCUS_OUT     = "focusOut"
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
