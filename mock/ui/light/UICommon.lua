module 'mock'
--------------------------------------------------------------------
local DEFAULT_TOUCH_PADDING = 20

CLASS: UICommon ( )
	:MODEL{}

function UICommon.setDefaultTouchPadding( pad )
	DEFAULT_TOUCH_PADDING = pad or 20
end

function UICommon.getDefaultTouchPadding()
	return DEFAULT_TOUCH_PADDING or 20
end
