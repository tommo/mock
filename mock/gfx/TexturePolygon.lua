module 'mock'

CLASS: TexturePolygon ( GraphicsPropComponent )
	:MODEL{
		Field 'verts'   :array() :no_edit();
		Field 'texture' :asset_pre('texture;render_target') :getset( 'Texture' );
		'----';
		Field 'fitPolygon' :boolean() :isset( 'FitPolygon' );
		'----';
		Field 'uvScale'  :type('vec2') :getset( 'UVScale' );
		Field 'uvOffset' :type('vec2') :getset( 'UVOffset' );
		

}

registerComponent( 'TexturePolygon', TexturePolygon )
mock.registerEntityWithComponent( 'TexturePolygon', TexturePolygon )


function TexturePolygon:__init()
	self.verts     = {
		 0 ,  20,
		-20, -20,
		 20, -20
	}
	self.aabb = {0,0,0,0}
	self.uvScale  = { 1,1 }
	self.uvOffset = { 0,0 }
	self.deck = PolygonDeck()
	self.polygonReady = false
	local moaiDeck = self.deck:getMoaiDeck()
	self.prop:setDeck( moaiDeck )
	self.fitPolygon = true
end

function TexturePolygon:onAttach( ent )
	TexturePolygon.__super.onAttach( self, ent )
	self:updatePolygon()
end

function TexturePolygon:isFitPolygon()
	return self.fitPolygon
end

function TexturePolygon:setFitPolygon( fit )
	self.fitPolygon = fit
	return self:updatePolygon()
end

function TexturePolygon:getUVOffset()
	return unpack( self.uvOffset )
end

function TexturePolygon:setUVOffset( x, y )
	self.uvOffset = { x, y }
	self.deck.uvOffset = self.uvOffset
	self:updatePolygon()
end

function TexturePolygon:getUVScale()
	return unpack( self.uvScale )
end

function TexturePolygon:setUVScale( x, y )
	self.uvScale = { x, y }
	self.deck.uvScale = self.uvScale
	self:updatePolygon()
end

function TexturePolygon:getVerts()
	return self.verts
end

function TexturePolygon:setVerts( verts )
	self.polygonReady = false
	self.verts = verts
	self:updatePolygon()
end

function TexturePolygon:getTexture()
	return self.texture
end

function TexturePolygon:setTexture( t )
	self.texture = t
	return self:updateDeck()
end

local append = table.append
function TexturePolygon:updatePolygon()
	if not self._entity then return end
	local tex = loadAsset( self.texture )
	local tw, th = 1, 1
	if tex then
		tw, th = tex:getSize()
	end
	--triangulate
	local fit = self.fitPolygon
	local x0,y0,x1,y1 = calcAABB( self.verts )
	self.aabb  = { x0, y0, x1, y1 }
	local w, h = x1 - x0, y1 - y0
	if w == 0 or h == 0 then return end
	local triangulated = PolygonHelper.triangulate( self.verts )
	local vertexList = {}
	for i, tri in ipairs( triangulated ) do
		for vi = 1, 3 do
			--xyuv
			local idx = (vi-1)*2
			local x, y = tri[ idx+1 ], tri[ idx+2 ]
			local u, v
			if fit then
				u, v = (x-x0) / w, (y-y0) / h
			else
				u, v = (x-x0) / tw, (y-y0) / th
			end
			append( vertexList, x,y,u,v )
		end
	end
	self.deck.vertexList = vertexList
	self.polygonReady = true
	return self:updateDeck()
end

function TexturePolygon:updateDeck()
	if not self.polygonReady then return end
	self.deck:setTexture( self.texture, false ) --dont resize
	self.deck:update()
	self.prop:forceUpdate()
end

function TexturePolygon:getLocalVerts( steps )
	return self.verts
end

function TexturePolygon:fitTextureUV()
	
end

function TexturePolygon:fitPolygonUV()

end

--------------------------------------------------------------------
local defaultMeshShader = MOAIShaderMgr.getShader( MOAIShaderMgr.MESH_SHADER )

function TexturePolygon:getDefaultShader()
	return defaultMeshShader
end
