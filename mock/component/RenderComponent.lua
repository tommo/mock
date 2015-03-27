module 'mock'

CLASS: RenderComponent()
	:MODEL{
		Field 'blend'            :enum( EnumBlendMode )      :getset('Blend');
		Field 'shader'           :asset( 'shader' )          :getset('Shader');
		'----';
		Field 'billboard'        :boolean()                  :set('setBillboard');
		Field 'depthMask'        :boolean()                  :set('setDepthMask');
		Field 'depthTest'        :enum( EnumDepthTestMode )  :set('setDepthTest');
	}

--------------------------------------------------------------------
local DEPTH_TEST_DISABLE = MOAIProp.DEPTH_TEST_DISABLE
function RenderComponent:__init()
	self.blend            = 'normal'
	self.shader           = false
	self.billboard        = false
	self.depthMask        = false
	self.depthTest        = DEPTH_TEST_DISABLE
end

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

function RenderComponent:setVisible( f )
end

function RenderComponent:isVisible()
	return true
end

function RenderComponent:setDepthMask( enabled )
	self.depthMask = enabled
end

function RenderComponent:setDepthTest( mode )
	self.depthTest = mode
end

function RenderComponent:setBillboard( billboard )
	self.billboard = billboard
end
