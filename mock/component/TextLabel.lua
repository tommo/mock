module 'mock'

local getBuiltinShader          = MOAIShaderMgr. getShader
local DECK2D_TEX_ONLY_SHADER    = MOAIShaderMgr. DECK2D_TEX_ONLY_SHADER
local DECK2D_SHADER             = MOAIShaderMgr. DECK2D_SHADER
local FONT_SHADER               = MOAIShaderMgr. FONT_SHADER

CLASS: TextLabel ()
	:MODEL{
		Field 'text'          :string()  :set('setText');
		Field 'stylesheet'    :asset('stylesheet') :getset( 'StyleSheet');
		Field 'defaultStyle'  :string()  :label('default') :set('setDefaultStyle');
		Field 'alignment'     :enum( EnumTextAlignment )  :set('setAlignment')  :label('align H');
		Field 'alignmentV'    :enum( EnumTextAlignmentV ) :set('setAlignmentV') :label('align V');
		Field 'size'          :type('vec2') :getset( 'Size' );
	}

function TextLabel:__init()
	local box = MOAITextBox.new()
	box:setShader( getBuiltinShader(DECK2D_SHADER) )
	-- box:setShader( getBuiltinShader(FONT_SHADER) )
	box:setStyle( getFallbackTextStyle() )
	box:setScl( 1,-1,1 )
	self.box  = box
	self.text = ''
	self.alignment  = 'left'
	self.alignmentV = 'top'
	self:setSize( 100, 100 )
	self.defaultStyle = 'default'
	self.styleSheet = false
	self:setStyleSheet( getDefaultStyleSheet() )
end

function TextLabel:onAttach( entity )
	entity:_attachProp( self.box )
end

function TextLabel:onDetach( entity )
	entity:_detachProp( self.box )
end

function TextLabel:setDefaultStyle( styleName )
	self.defaultStyle = styleName or 'default'
	self:updateStyles()
end

function TextLabel:setStyleSheet( sheetPath ) 
	local box = self.box
	self.styleSheetPath = sheetPath
	self.styleSheet = loadAsset( sheetPath )
	self:updateStyles()
end

function TextLabel:updateStyles()
	if self.styleSheet then
		self.styleSheet:applyToTextBox( self.box, self.defaultStyle )	
	end
end

function TextLabel:getStyleSheet()
	return self.styleSheetPath
end

function TextLabel:getSize()
	return self.w, self.h
end

function TextLabel:setSize( w, h )
	self.w = w or 100
	self.h = h or 100
	self:updateRect()
end

function TextLabel:updateRect()
	local w, h = self.w, self.h
	local align = self.alignment
	if align == 'left' then
		self.box:setRect( 0, 0, w, h )
	elseif align == 'center' then
		self.box:setRect( -w/2, 0, w/2, h )
	else --'right'
		self.box:setRect( -w, 0, 0, h )
	end
	self.box:setString( self.text ) --trigger layout
end
	
function TextLabel:setText( text )
	self.text = text
	self.box:setString( text )
end

function TextLabel:getText( )
	return self.text
end

--------------------------------------------------------------------
local textAlignments = {
	center    = MOAITextLabel.CENTER_JUSTIFY,
	left      = MOAITextLabel.LEFT_JUSTIFY,
	right     = MOAITextLabel.RIGHT_JUSTIFY,
	top       = MOAITextLabel.TOP_JUSTIFY,
	bottom    = MOAITextLabel.BOTTOM_JUSTIFY,
	baseline  = MOAITextLabel.BASELINE_JUSTIFY,
}

function TextLabel:setAlignment( align )
	align = align or 'left'
	self.alignment = align
	self.box:setAlignment( textAlignments[ align ] )
	self:updateRect()
end

function TextLabel:setAlignmentV( align )
	align = align or 'top'	 
	self.alignmentV = align
	self.box:setAlignment( textAlignments[ self.alignment ], textAlignments[ align ] )
	self:updateRect()
end

function TextLabel:getBounds()
	return self.box:getBounds()	
end

function TextLabel:drawBounds()
	GIIHelper.setVertexTransform( self.box )
	local x1,y1, x2,y2 = self.box:getRect()
	MOAIDraw.drawRect( x1,y1,x2,y2 )
end


function TextLabel:inside( x, y, z, pad )
	return self.box:inside( x,y,z, pad )	
end

function TextLabel:setScissorRect( s )
	self.box:setScissorRect( s )
end


registerComponent( 'TextLabel', TextLabel )