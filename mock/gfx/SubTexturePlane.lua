module 'mock'

CLASS: SubTexturePlane ( GraphicsPropComponent )
	:MODEL{
		Field 'texture' :asset_pre(getSupportedTextureAssetTypes()) :getset( 'Texture' );
		'----';
		Field 'offset'  :type('vec2') :getset('Offset');
		Field 'size'    :type('vec2') :getset('Size');
		Field 'origin'  :enum( EnumOrigin ) :set('setOrigin');
		'----';
		Field 'resetSize' :action( 'resetSize' );
	}

registerComponent( 'SubTexturePlane', SubTexturePlane )
mock.registerEntityWithComponent( 'SubTexturePlane', SubTexturePlane )

function SubTexturePlane:__init()
	self.texture = false
	self.offx = 0
	self.offy = 0
	self.w = 100
	self.h = 100
	self.deck = Quad2D()
	self.prop:setDeck( self.deck:getMoaiDeck() )
	self.origin = 'middle_center'
end

function SubTexturePlane:getTexture()
	return self.texture
end

function SubTexturePlane:setTexture( t )
	self.texture = t
	self.deck:setTexture( t, false ) --dont resize
	self.deck:update()
	self:updateSize()
end

function SubTexturePlane:getSize()
	return self.w, self.h
end

function SubTexturePlane:setSize( w, h )
	self.w = w
	self.h = h
	self:updateSize()
end

function SubTexturePlane:getOffset()
	return self.offx, self.offy
end

function SubTexturePlane:setOffset( x, y )
	self.offx = x
	self.offy = y
	self:updateSize()
end

function SubTexturePlane:setOrigin( origin )
	self.origin = origin
	self:updateSize()
end

function SubTexturePlane:resetSize()
	if self.texture then
		local tex = loadAsset( self.texture )
		self.offx = 0
		self.offy = 0
		self.w, self.h = tex:getSize()
		return self:updateSize()
	end
end

function SubTexturePlane:updateSize()
	local tex = loadAsset( self.texture )
	if not tex then return end
	local w, h   = self.w,  self.h
	local tw, th = tex:getSize()
	local offx, offy = self.offx, self.offy
	local origin = self.origin
	-- local ox, oy = rectOrigin( self.origin, 0,0,tw,th )
	local tex, uv = tex:getMoaiTextureUV()
	local du, dv = uv[3] - uv[1], uv[4] - uv[2]
	
	local px0,py0,px1,py1
	local originY, originX = splitOriginName( origin )
	if originX == 'center' then
		px0 = (tw-w)/2
		px1 = px0 + w
	elseif originX == 'left' then
		px0 = 0
		px1 = w
	elseif originX == 'right' then
		px1 = tw
		px0 = px1 - w
	end

	if originY == 'middle' then
		py0 = (th-h)/2
		py1 = py0 + h
	elseif originY == 'bottom' then
		py0 = 0
		py1 = h
	elseif originY == 'top' then
		py1 = th
		py0 = py1 - h
	end

	local u0 = (px0+offx)/tw * du + uv[1]
	local v0 = (py0+offy)/th * du + uv[2]
	local u1 = (px1+offx)/tw * dv + uv[1]
	local v1 = (py1+offy)/th * dv + uv[2]

	self.deck:getMoaiDeck():setRect( -w/2,-h/2,w/2,h/2)
	self.deck:getMoaiDeck():setUVRect( u0, v0, u1, v1 )
	self.prop:forceUpdate()
end

--------------------------------------------------------------------
function SubTexturePlane:drawBounds()
	GIIHelper.setVertexTransform( self.prop )
	local x1,y1,z1, x2,y2,z2 = self.prop:getBounds()
	MOAIDraw.drawRect( x1,y1,x2,y2 )
end

