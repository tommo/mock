module 'mock'

CLASS: UIButton ( UIWidget )
	:MODEL{

	}
	:SIGNAL{
		clicked = '';
	}

registerEntity( 'UIButton', UIButton )

function UIButton:__init()
	self.pressed = false
end

function UIButton:procEvent( ev )
	local t = ev.type
	if t == UIEvent.TOUCH_DOWN then
		self.pressed = true
		self:setState( 'press' )
		return self:onPress()
	elseif t == UIEvent.TOUCH_UP then
		if self.pressed then
			self.pressed = false
			self:setState( 'normal' )
			self.clicked()
		end
		return self:onRelease()
	end
end

function UIButton:onPress()
end

function UIButton:onRelease()
end

function UIButton:onClick()
end
