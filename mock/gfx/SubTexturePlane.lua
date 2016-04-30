module 'mock'

CLASS: SubTexturePlane ( GraphicsPropComponent )
	:MODEL{
		Field 'texture' :asset_pre('texture;render_target') :getset( 'Texture' );
		'----';
		Field 'offset'  :type('vec2') :getset('Offset');
		Field 'size'    :type('vec2') :getset('Size');
		'----';
		Field 'resetSize' :action( 'resetSize' );
	}

registerComponent( 'SubTexturePlane', SubTexturePlane )
mock.registerEntityWithComponent( 'SubTexturePlane', SubTexturePlane )

function SubTexturePlane:__init()
	self.texture = false
	self.ox = 0
	self.oy = 0
	self.w = 100
	self.h = 100
	self.deck = Quad2D()
	self.prop:setDeck( self.deck:getMoaiDeck() )
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
	return self.ox, self.oy
end

function SubTexturePlane:setOffset( x, y )
	self.ox = x
	self.oy = y
	self:updateSize()
end

function SubTexturePlane:resetSize()
	if self.texture then
		local tex = loadAsset( self.texture )
		self.ox = 0
		self.oy = 0
		self.w, self.h = tex:getSize()
		return self:updateSize()
	end
end

function SubTexturePlane:updateSize()
	local tex = loadAsset( self.texture )
	if not tex then return end
	local w, h   = self.w,  self.h
	local ox, oy = self.ox, self.oy
	local tex, uv = tex:getMoaiTextureUV()
	local tw, th = tex:getSize()
	local du, dv = uv[3] - uv[1], uv[4] - uv[2]
	local u0 = ox/tw * du + uv[1]
	local v0 = oy/th * du + uv[2]
	local u1 = (ox+w)/tw * dv + uv[1]
	local v1 = (oy+h)/th * dv + uv[2]

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

