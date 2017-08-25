module 'mock'

--------------------------------------------------------------------
local function buildCircleVerts( radius, spans, ox,oy, sx,sy )
	local halfspans = math.floor( math.max( spans or 0 , 6 )/2 )
	local step = math.pi / halfspans
	local verts = {}
	for i = 1, halfspans do
		local a1 = ( i - 1 + 0.5 ) * step
		local a0 = -a1
		local ix0, iy0 = math.cos( a0 ) * radius, math.sin( a0 ) * radius
		local ix1, iy1 = math.cos( a1 ) * radius, math.sin( a1 ) * radius
		local u0 = ix0/radius/2 * sx + 0.5 + ox
		local v0 = iy0/radius/2 * sy + 0.5 + oy
		local u1 = ix1/radius/2 * sx + 0.5 + ox
		local v1 = iy1/radius/2 * sy + 0.5 + oy
		local k = ( i-1 ) * 8
		--
		verts[ k +1 ]  = ix0
		verts[ k +2 ]  = iy0
		verts[ k +3 ]  = u0
		verts[ k +4 ]  = v0
		--
		verts[ k +5 ]  = ix1
		verts[ k +6 ]  = iy1
		verts[ k +7 ]  = u1
		verts[ k +8 ]  = v1
	end
	return MOAIMesh.GL_TRIANGLE_STRIP, verts
end

--------------------------------------------------------------------
local function buildSectorVerts( radius, spans, ox,oy, sx,sy, startArc, endArc )
	if endArc < startArc then
		endArc = endArc + 360
	end
	local diff = endArc - startArc
	if diff<=0 then return end
	if diff>=360 then return buildCircleVerts( radius, spans, ox,oy, sx,sy ) end

	local spans = math.max( math.ceil( diff/360 * spans ), 2 )
	local step = math.pi * (diff/180) / spans
	local verts = {}
	for i = 0, spans + 1 do
		local ix0, iy0
		if i == 0 then
			ix0, iy0 = 0, 0
		else
			local a0 = ( i - 1 ) * step + startArc*math.pi/180
			ix0, iy0 = math.cos( a0 ) * radius, math.sin( a0 ) * radius
		end
		local u0 = ix0/radius/2 * sx + 0.5 + ox
		local v0 = iy0/radius/2 * sy + 0.5 + oy

		local k = i * 4
		verts[ k +1 ]  = ix0
		verts[ k +2 ]  = iy0
		verts[ k +3 ]  = u0
		verts[ k +4 ]  = v0

	end

	return MOAIMesh.GL_TRIANGLE_FAN, verts
end

--------------------------------------------------------------------
CLASS: TextureCircle ( GraphicsPropComponent )
	:MODEL{
		Field 'texture' :asset(getSupportedTextureAssetTypes()) :getset( 'Texture' );
		Field 'radius'  :onset('update');
		Field 'spans'   :int() :onset('update');
		'----';
		Field 'scale'   :type('vec2') :getset('Scale')  :range(0,1000);
		Field 'offset'  :type('vec2') :getset('Offset') :range(-100,100);
		'----';
		Field 'startArc' :onset('update');
		Field 'endArc'   :onset('update');
	}

registerComponent( 'TextureCircle', TextureCircle )
registerEntityWithComponent( 'TextureCircle', TextureCircle )

function TextureCircle:__init()
	self.texturePath = false
	self.radius = 100
	self.spans  = 8
	
	self.deck = PolygonDeck()	
	self.prop:setDeck( self.deck:getMoaiDeck() )	
	self.prop:setDepthMask( true )
	self.prop:setDepthTest( MOAIProp.DEPTH_TEST_LESS_EQUAL )
	
	self.ox = 0
	self.oy = 0
	self.sx = 100
	self.sy = 100
	self.startArc = 0
	self.endArc   = 360
end

function TextureCircle:getTexture()
	return self.texturePath
end

function TextureCircle:setTexture( t )
	self.texturePath = t
	self.deck:setTexture( t, false ) --dont resize
	self:update()
end

function TextureCircle:getOffset()
	return self.ox, self.oy
end

function TextureCircle:setOffset( x, y )
	self.ox = x
	self.oy = y
	self:update()
end

function TextureCircle:getScale()
	return self.sx, self.sy
end

function TextureCircle:setScale( sx, sy )
	self.sx = sx
	self.sy = sy
	self:update()
end

function TextureCircle:setSection( s, e )
	self.startArc = s
	self.endArc   = e
	self:update()
end

function TextureCircle:update()
	local primType, verts  = buildSectorVerts( 
		self.radius, self.spans,
		self.ox/100, self.oy/100, 
		self.sx/100, self.sy/100,
		self.startArc, self.endArc
	)
	if not primType then return self.prop:setVisible( false ) end
	self.prop:setVisible( true )
	self.deck.vertexList = verts or {}
	self.deck:update()

	local mesh = self.deck:getMoaiDeck()
	mesh:setPrimType ( primType )
	self.prop:forceUpdate()

end

