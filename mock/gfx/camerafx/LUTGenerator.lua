module 'mock'

--------------------------------------------------------------------
CLASS: LUTGeneratorCameraPass ( CameraPass )

function LUTGeneratorCameraPass:onInit()
end


function LUTGeneratorCameraPass:onBuild()
	--OUPUT
	local size = self:getCamera().LUTSize
	self:pushDefaultRenderTarget()
	local layer, prop, quad = self:buildSingleQuadRenderLayer( 
		TextureHelper.buildBaseLUT( size )
	)
	prop:setScl( 1, -1, 1 )
	self:pushRenderLayer( layer )
	self:pushCallback( function()
		print( 'draw!' )
	end)
end


--------------------------------------------------------------------
CLASS: LUTGeneratorCamera ( TextureTargetCamera )
	:MODEL{}

function LUTGeneratorCamera:__init( size )
	size = size or 32
	self.LUTSize = size
	self:setTargetSize( size*size, size )
end

function LUTGeneratorCamera:setLUTSize( size )
	self.LUTSize = size
	self:setTargetSize( size * size, size )
end

function LUTGeneratorCamera:loadPasses()
	self:addPass( LUTGeneratorCameraPass() )
end
