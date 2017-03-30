module 'mock'

CLASS: UILabel ( UIWidget )
	:MODEL{
		Field 'text' :string() :getset( 'Text' );
}

mock.registerEntity( 'UILabel', UILabel )

function UILabel:__init()
	self.text = 'Label Text'
end

function UILabel:onLoad()
	self:setRenderer( UILabelRenderer() )
end

function UILabel:getText( t )
	return self.text
end

function UILabel:setText( t )
	self.text = t
	self:invalidateContent()
end

function UILabel:getContentData( key, role )
	if key == 'text' then
		return self.text
	end
end
