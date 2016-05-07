module 'mock'

--------------------------------------------------------------------
CLASS: ColorGradingBuildingContext ()
	:MODEL{}

function ColorGradingBuildingContext:__init()
	self.outputFrameBuffer = false
end

function ColorGradingBuildingContext:build()

end

--------------------------------------------------------------------
CLASS: ColorGradingConfig ()
	:MODEL{}

function ColorGradingConfig:__init()
	self.nodeList = {}
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
CLASS: ColorGradingNodeInvert ( ColorGradingNode )
	:MODEL{
}

--------------------------------------------------------------------
CLASS: ColorGradingNodeBW ( ColorGradingNode )
	:MODEL{}

--------------------------------------------------------------------
CLASS: ColorGradingNodeHSL ( ColorGradingNode )
	:MODEL{
		Field 'hue';
		Field 'saturation';
		Field 'lightness';
}

function ColorGradingNodeHSL:__init()
	self.hue = 0 
	self.saturation = 0
	self.lightness = 0
end

--------------------------------------------------------------------
CLASS: ColorGradingNodeCurve ( ColorGradingNode )
	:MODEL{}

--------------------------------------------------------------------
CLASS: ColorGradingNodeColorBalance ( ColorGradingNode )
	:MODEL{
		Field 'preserveLightness' :boolean();
}

function ColorGradingNodeColorBalance:__init()
	self.preserveLightness = false
end


--------------------------------------------------------------------
CLASS: ColorGradingNodeHueFocus ( ColorGradingNode )
	:MODEL{}

--------------------------------------------------------------------
CLASS: ColorGradingNodeReference ( ColorGradingNode )
	:MODEL{
		Field 'source' :asset( 'color_grading_config' )
}

