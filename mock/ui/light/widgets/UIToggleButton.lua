module 'mock'

CLASS: UIToggleButton ( UIButton )
	:MODEL{
		Field 'checked' :boolean() :isset( 'Checked' )
	}
	:SIGNAL{
		valueChanged = '';
	}

function UIToggleButton:__init()
	self.checked = false
end

function UIToggleButton:toggleChecked()
	return self:setChecked( not self.checked )
end

function UIToggleButton:setChecked( checked )
	checked = checked and true or false
	if self.checked == checked then return end
	self.checked = checked
	self.valueChanged( self.checked )
	self:updateStyleState()
end

function UIToggleButton:isChecked()
	return self.checked
end

function UIToggleButton:getMinSizeHint()
	return 80, 40
end

function UIToggleButton:onClicked()
	self:toggleChecked()
end

function UIToggleButton:updateStyleState()
	if self.checked then
		return self:setState( 'press' )
	end
	return UIToggleButton.__super.updateStyleState( self )
end

registerEntity( 'UIToggleButton', UIToggleButton )
