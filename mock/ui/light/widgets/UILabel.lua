module 'mock'

CLASS: UILabel ( UIWidget )
	:MODEL{}

function UILabel:onLoad()
end

function UILabel:setText( t )
	self.textBox:setText( t )
end

function UILabel:initContent( style )
	self:initCommonContent( style )
	self.textBox = self:attachInternal( TextLabel() )
end

function UILabel:updateStyle( style )
	self.textBox:setAlignment( style:get( self, 'align' ) )
end

function UILabel:updateContent( style )
end

function UILabel:initCommonContent( style )

end

function UILabel:initCommonBackground( style )
	local background = style:get( self, 'background' )
end

