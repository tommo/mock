module 'mock'

CLASS: UITextArea ( UIWidget )
	:MODEL{
		Field 'text' :string() :getset( 'Text' ) :widget('textbox');
}

mock.registerEntity( 'UITextArea', UITextArea )

function UITextArea:__init()
	self.text = 'Label Text'
end

function UITextArea:onLoad()
	self:setRenderer( UITextAreaRenderer() )
end

function UITextArea:getText( t )
	return self.text
end

function UITextArea:setText( t )
	self.text = t
	self:invalidateContent()
end

function UITextArea:getContentData( key, role )
	if key == 'text' then
		return self.text
	end
end
