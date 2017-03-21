module 'mock'

CLASS: UISimpleButton ( UIButton )
	:MODEL{
	}

function UISimpleButton:getMinSizeHint()
	return 80, 40
end

registerEntity( 'UISimpleButton', UISimpleButton )
