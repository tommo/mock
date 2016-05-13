module 'mock'


--------------------------------------------------------------------
CLASS: ColorGradingNode ()
	:MODEL{
		Field 'active' :boolean();
		Field 'intensity' :range(0,1) :meta{ step = 0.1 };
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
	self.lutGenerator = LUTGeneratorCamera()
	self.texture = self.lutGenerator.targetTexture
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
	
	local context
	--todo:
	for i, node in ipairs( self.nodeList ) do
		node:build( context )
	end
	self.dirty = false

end

function ColorGradingConfig:getTexture()
	self:build()
	return self.texture
end

--------------------------------------------------------------------
function ColorGradingConfigLoader( node )
	local data   = mock.loadAssetDataTable( node:getObjectFile('data') )
	local config = deserialize( nil, data )
	config:build()
	return config
end

registerAssetLoader ( 'color_grading', ColorGradingConfigLoader )
