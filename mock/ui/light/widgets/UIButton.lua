module 'mock'

CLASS: UIButton ( UIWidget )
	:MODEL{
		Field 'text' :string() :getset( 'Text' );
	}
	:SIGNAL{
		clicked = '';
	}

function UIButton:__init()
	self.hovered = false
	self.pressed = false
	self.text = 'Button'
	self.layoutPolicy = { 'expand', 'expand' }
end

function UIButton:onLoad()
	self:setRenderer( UIButtonRenderer() )
end

function UIButton:setText( t )
	self.text = t
	self:invalidateContent()
end

function UIButton:getText()
	return self.text
end

function UIButton:getContentData( key, role )
	if key == 'text' then
		return self:getText()
	end
end

function UIButton:updateStyleState()
	if self.pressed then
		return self:setState( 'press' )
	end

	if self.hovered then
		return self:setState( 'hover' )
	end

	return self:setState( 'normal' )
end


function UIButton:procEvent( ev )
	local t = ev.type
	local d = ev.data
	if t == UIEvent.POINTER_ENTER then
		self.hovered = true
		self:updateStyleState()

	elseif t == UIEvent.POINTER_EXIT then
		self.hovered = false
		self:updateStyleState()

	elseif t == UIEvent.POINTER_DOWN then
		self.pressed = true
		self:updateStyleState()
		return self:onPress()

	elseif t == UIEvent.POINTER_UP then
		if self.pressed then
			self.pressed = false
			self:updateStyleState()
			local px,py,pz = self:getWorldLoc()
			if self:inside( d.x, d.y, pz, self:getTouchPadding() ) then
				self:onClick()
				self.clicked()
			end
		end
		return self:onRelease()

	end
end

function UIButton:getLabelRect()
	return self:getContentRect()
end

function UIButton:onPress()
end

function UIButton:onRelease()
end

function UIButton:onClick()
end

