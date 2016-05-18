module 'mock'


--------------------------------------------------------------------
CLASS: ColorGradingNode ()
	:MODEL{
		Field 'active' :boolean();
		Field 'intensity' :range(0,1) :meta{ step = 0.1 } :widget('slider');
}

function ColorGradingNode:__init()
	self.parentConfig = false
	self.active = true
	self.intensity = 1
	self.dirty = true
end

function ColorGradingNode:markDirty()
	self.dirty = true
	self.parentConfig:markDirty()
end

function ColorGradingNode:setIntensity( i )
	self.intensity = i
	self:markDirty()
end

function ColorGradingNode:build( buildContext )
	self:onBuild( buildContext )
	self.dirty = false
end

function ColorGradingNode:onBuild( buildContext )
end


--------------------------------------------------------------------
CLASS: ColorGradingConfig ()
	:MODEL{
		Field 'nodeList' :array( ColorGradingNode )
}

function ColorGradingConfig:__init()
	self.nodeList = {}
	self.prebuiltTexture = false
	self.dirty = true
end

function ColorGradingConfig:appendNode( node )
	table.insert( self.nodeList, node )
	node.parentConfig = self
	self:markDirty()
	return node
end

function ColorGradingConfig:prependNode( node )
	table.insert( self.nodeList, 1, node )
	node.parentConfig = self
	self:markDirty()
	return node
end

function ColorGradingConfig:insertNode( node, i )
	table.insert( self.nodeList, i, node )
	node.parentConfig = self
	self:markDirty()
	return node
end

function ColorGradingConfig:removeNode( node )
	local idx = table.index( self.nodeList, node )
	if idx then
		node.parentConfig = false
		table.remove( self.nodeList, idx )
		return true
	end
	return false
end

function ColorGradingConfig:markDirty()
	self.dirty = true
end

function ColorGradingConfig:build( forced )
	if not ( self.forced or self.dirty ) then return end
	local size = 8
	
	for i, node in ipairs( self.nodeList ) do
		node:build( context )
	end
	
	-- self.lutGenerator:addImageEffect( effect, false )
	local camera = LUTGeneratorCamera()
	camera:setLUTSize( size )
	local effect = mock.CameraImageEffectInvert()
	-- effect.intensity = 0
	-- effect:updateIntensity()
	 local effect = mock.CameraImageEffectSepia()
	effect.intensity = 1
	effect:updateIntensity()
	camera:addImageEffect( effect, false )

	camera:loadPasses()
	camera:manualRender()

	local image   = MOAIImage.new()
	camera:grabCurrentFrame( image )
	local texture = MOAIImageTexture.new()
	local w,h = size*size,size
	texture:init( w,h )
	texture:setFilter( MOAITexture.GL_LINEAR )
	texture:copyBits( image, 0,0, 0,0, w,h )
	texture:invalidate()
	self.prebuiltTexture = texture
	self.dirty = false
end

function ColorGradingConfig:getTexture()
	self:build()
	return self.prebuiltTexture
end

--------------------------------------------------------------------
function ColorGradingConfigLoader( node )
	local data   = mock.loadAssetDataTable( node:getObjectFile('data') )
	local config = deserialize( nil, data )
	config:build()
	return config
end

registerAssetLoader ( 'color_grading', ColorGradingConfigLoader )
