module 'mock'


--------------------------------------------------------------------
CLASS: UIWidgetRenderer ()
	:MODEL{}

function UIWidgetRenderer:__init()
	self.widget = false
	self.options = {}
end

function UIWidgetRenderer:setOptions( options )
	local options0 = self.options
	for k, v in pairs( options ) do
		options0[ k ] = v
	end
end

function UIWidgetRenderer:setOption( k, v )
	self.options[ k ] = v
end

function UIWidgetRenderer:getOption( k, default )
	local v = self.options[ k ]
	if v == nil then return default end
	return v
end

function UIWidgetRenderer:setWidget( widget )
	self.widget = widget
end

function UIWidgetRenderer:getWidget()
	return self.widget
end

function UIWidgetRenderer:init()
	self:onInit( self.widget, self.options )
end

function UIWidgetRenderer:onInit( widget )
end

function UIWidgetRenderer:update( widget, style, updateStyle, updateContent )
	if updateStyle then
		self:onUpdateStyle( widget, style )
	end
	self:onUpdateSize( widget, style )
	if updateContent then
		self:onUpdateContent( widget, style )
	end

end

function UIWidgetRenderer:onUpdateContent( widget, style )
end

function UIWidgetRenderer:onUpdateSize( widget, style )
end

function UIWidgetRenderer:onUpdateStyle( widget, style )
end

function UIWidgetRenderer:onDestroy( widget )
end

