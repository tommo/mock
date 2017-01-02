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
	local d = ev.data
	if t == UIEvent.TOUCH_DOWN then
		self.pressed = true
		self:setState( 'press' )
		return self:onPress()

	elseif t == UIEvent.TOUCH_UP then
		if self.pressed then
			self.pressed = false
			self:setState( 'normal' )
			local px,py,pz = self:getWorldLoc()
			if self:inside( d.x, d.y, pz, self:getTouchPadding() ) then
				self.clicked()
			end
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
