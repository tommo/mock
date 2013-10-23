module 'mock'

CLASS: RenderComponent()
	:MODEL{
		Field 'blend'  :enum( mock.EnumBlendModes ) :getset('Blend');
		Field 'shader' :boolean()
	}

--------------------------------------------------------------------
function RenderComponent:getBlend()
	return self.blend
end

function RenderComponent:setBlend( b )
	self.blend = b	
end
