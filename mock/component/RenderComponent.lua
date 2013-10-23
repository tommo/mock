module 'mock'

CLASS: RenderComponent()
	:MODEL{
		Field 'blend'  :enum( mock.EnumBlendModes ) :getset('Blend');
		Field 'shader' :asset( 'shader' ) :getset('Shader');
	}

--------------------------------------------------------------------
function RenderComponent:getBlend()
	return self.blend
end

function RenderComponent:setBlend( b )
	self.blend = b	
end


function RenderComponent:setShader( s )
	self.shader = s
end

function RenderComponent:getShader( s )
	return self.shader
end

