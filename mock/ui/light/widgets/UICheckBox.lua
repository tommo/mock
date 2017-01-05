module 'mock'


--------------------------------------------------------------------
CLASS: UICheckBox ( UISimpleButton )
	:MODEL{
		Field 'text' :string() :getset( 'Text' );
		Field 'checked' :boolean() :isset( 'Checked' );
	}
	:SIGNAL{
		valueChanged = '';
	}

function UICheckBox:__init()
	self.checked = false
	self.markSprite = self:attachInternal( DeckComponent() )
	self.markSprite:hide()
	self:connect( self.clicked, 'toggleChecked' )
end

function UICheckBox:toggleChecked()
	return self:setChecked( not self.checked )
end

function UICheckBox:setChecked( checked )
	checked = checked and true or false
	if self.checked == checked then return end
	self.checked = checked
	self:invalidateStyle()
	self.markSprite:setVisible( checked )
	self.valueChanged( self.checked )
end

function UICheckBox:isChecked()
	return self.checked
end

function UICheckBox:getLabelRect()
end

function UICheckBox:onUpdateVisual( style )
	UICheckBox.__super.onUpdateVisual( self, style )
	local markSpriteDeck = style:getAsset( 'mark_sprite' )
	if markSpriteDeck then
		self.markSprite:setDeck( markSpriteDeck )
		self.markSprite:setRect( self:getLocalRect() )
	end
end


registerEntity( 'UICheckBox', UICheckBox )
