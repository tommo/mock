module 'mock'


--------------------------------------------------------------------
local SupportedTextureAssetTypes = ''
function getSupportedTextureAssetTypes()
	return SupportedTextureAssetTypes
end

function addSupportedTextureAssetType( t )
	if SupportedTextureAssetTypes ~= '' then
		SupportedTextureAssetTypes = SupportedTextureAssetTypes .. ';'
	end
	SupportedTextureAssetTypes = SupportedTextureAssetTypes .. t
end


--------------------------------------------------------------------
CLASS: TextureInstanceBase ()
	:MODEL{}


function TextureInstanceBase:getSize()
	return 1, 1
end

function TextureInstanceBase:getOrignalSize()
	return self:getSize()
end

function TextureInstanceBase:getOutputSize()
	return self:getSize()
end

function TextureInstanceBase:getMoaiTexture()
end

function TextureInstanceBase:getMoaiTextureUV()
	local tex = self:getMoaiTexture()
	local uvrect = { self:getUVRect() }
	return tex, uvrect
end

function TextureInstanceBase:getUVRect()
	return 0,0,1,1
end

function TextureInstanceBase:isPacked()
	return false
end
