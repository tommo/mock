module 'mock'

registerSignals{
	'ui.button.press',
	'ui.button.release',
	'ui.button.click',
}

CLASS: GUIButtonBase ( GUIWidget )
	:MODEL{
		'----';
		Field 'msg'  :string();
		Field 'data' :string();
		'----';
	}

function GUIButtonBase:onLoad()
end

function GUIButtonBase:onPress	( touch, x, y )
	self:setState 'press'
	self:emit( 'ui.button.press', self )
	self:updateState()
end

function GUIButtonBase:onStateChange()
	return self:updateState()
end

function GUIButtonBase:onRelease( touch, x, y )
	self:setState 'normal'
	self:emit( 'ui.button.release', self )
	local px,py,pz = self:getWorldLoc()
	if self:inside( x,y,pz, getDefaultTouchPadding() ) then
		self:emit( 'ui.button.click', self )
		local onClick=self.onClick
		if onClick then onClick( self ) end		
	end
	self:updateState()
end

function GUIButtonBase:onClick()
end

function GUIButtonBase:updateState()
end
