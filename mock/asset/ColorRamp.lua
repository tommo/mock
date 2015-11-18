module 'mock'

CLASS: ColorRamp ()
	:MODEL{}

function ColorRamp:__init()
	self._ramp = MOAIColorRamp.new()
end

function ColorRamp:getColor( pos )
	if pos then 
		return self._ramp:getColorAtPos( pos )
	end
end

function ColorRamp:getImage( w, h )
	local img = self._ramp:createImage( w, h )
end

function ColorRamp:getTexture( w, h )
	local img = self:getImage( w, h )
	local tex = MOAITexture.new()
	tex:setFilter( MOAITexture.GL_LINEAR )
	tex:setWrap( true )
	tex:load( img )
	return tex
end

