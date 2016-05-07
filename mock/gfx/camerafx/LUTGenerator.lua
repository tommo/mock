module 'mock'

function _generateLUT()
	local img = MOAIImageTexture.new()
	img:init( 1024, 32 )
	local set = img.setRGBA
	for z = 1, 32 do
		for x = 1, 32 do
			for y = 1, 32 do 
				local r,g,b = (x-1)/31, (y-1)/31, (z-1)/31
				set( img, x + ( z - 1 ) * 32 - 1, y - 1, r, g, b, 1 )
			end
		end
	end
	return img
end

local BaseLUT = false
function getBaseLUT()
	if BaseLUT then return BaseLUT end
	BaseLUT = _generateLUT()
	return BaseLUT
end


--------------------------------------------------------------------
CLASS: LUTGeneratorCameraPass ( CameraPass )

function LUTGeneratorCameraPass:onInit()
end


function LUTGeneratorCameraPass:onBuild()
	--OUPUT
	self:pushDefaultRenderTarget()
	local layer, prop, quad = self:buildSingleQuadRenderLayer( getBaseLUT() )
	self:pushRenderLayer( layer )
end


--------------------------------------------------------------------
CLASS: LUTGeneratorCamera ( Camera )
	:MODEL{}

function LUTGeneratorCamera:__init()
	self.targetTexture = RenderTargetTexture()
	self.targetTexture:init( 1024, 32 )
	self:setOutputRenderTarget( self.targetTexture:getRenderTarget() )
end

function LUTGeneratorCamera:getLUT()
	return self.targetTexture
end

function LUTGeneratorCamera:getMoaiFrameBuffer()
	return self.targetTexture:getMoaiFrameBuffer()
end

function LUTGeneratorCamera:loadPasses()
	self:addPass( LUTGeneratorCameraPass() )
end
