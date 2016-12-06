module 'mock'

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

