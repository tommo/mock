module 'mock'

CLASS: UIButton ( UIWidget )
	:MODEL{
		Field 'text' :string() :getset( 'Text' );
	}
	:SIGNAL{
		pressed  = 'onPressed';
		released = 'onReleased';
		clicked  = 'onClicked';
	}

function UIButton:__init()
	self._hoverd = false
	self._pressed = false
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
	if self._pressed then
		return self:setState( 'press' )
	end

	if self._hoverd then
		return self:setState( 'hover' )
	end

	return UIButton.__super.updateStyleState( self )
end


function UIButton:procEvent( ev )
	local t = ev.type
	local d = ev.data
	if t == UIEvent.POINTER_ENTER then
		self._hoverd = true
		self:updateStyleState()

	elseif t == UIEvent.POINTER_EXIT then
		self._hoverd = false
		self:updateStyleState()

	elseif t == UIEvent.POINTER_DOWN then
		self._pressed = true
		self:updateStyleState()
		self.pressed:emit()
		return

	elseif t == UIEvent.POINTER_UP then
		if self._pressed then
			self._pressed = false
			self:updateStyleState()
			local px,py,pz = self:getWorldLoc()
			if self:inside( d.x, d.y, pz, self:getTouchPadding() ) then
				self.clicked:emit()
			end
		end
		self.released:emit()
		return

	end
end

function UIButton:getLabelRect()
	return self:getContentRect()
end

----
function UIButton:onPressed()
end

function UIButton:onReleased()
end

function UIButton:onClicked()
end

