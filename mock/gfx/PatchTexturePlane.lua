module 'mock'

CLASS: PatchTexturePlane ( TexturePlane )

mock.registerComponent( 'PatchTexturePlane', PatchTexturePlane )

function PatchTexturePlane:__init()
	self.deck = StretchPatch()
	self.prop:setDeck( self.deck:getMoaiDeck() )
	self.w = 100
	self.h = 100
end

function PatchTexturePlane:setTexture( t )
	PatchTexturePlane.__super.setTexture( self, t )
	if self.texture then
		local tex = loadAsset( self.texture )
		if tex then
			local w, h = tex:getSize()
			self.deck:setSize( w, h )
			self.deck:update()
			local d = self:getMoaiDeck()
			self:updateSize()
		end
	end
end

function PatchTexturePlane:sizeToScl(w,h)
	local patch = self:getMoaiDeck()
	if patch then
		local pw, ph = patch.patchWidth or w, patch.patchHeight or h
		return w / pw, h / ph
	else
		return w,h
	end
end

function PatchTexturePlane:sclToSize( sx, sy )	
	local patch=self:getMoaiDeck()
	if patch then
		local pw, ph = patch.patchWidth or 1, patch.patchHeight or 1
		return sx*pw, sy*ph
	else
		return sx, sy
	end
end

function PatchTexturePlane:updateSize()
	self.prop:setScl( self:sizeToScl( self.w, self.h ) )
end

function PatchTexturePlane:getSize()
	return self.w, self.h
end

function PatchTexturePlane:setSize(w,h)
	self.w = w
	self.h = h
	self:updateSize()
end