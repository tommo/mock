module 'mock'

function NamedTilesetLoader( node )
	local pack = loadAsset( node.parent )
	local name = node:getName()	
	local item = pack:getTileset( name )
	return item
end

function NamedTilesetPackLoader( node )
	local atlasFile = node:getObjectFile( 'atlas' )
	local defFile = node:getObjectFile( 'def' )
	-- local defData = loadAssetDataTable( defFile )
	local pack = NamedTilesetPack()
	pack:load( defFile, atlasFile )
	return pack
end

registerAssetLoader ( 'named_tileset',         NamedTilesetLoader )
registerAssetLoader ( 'named_tileset_pack',    NamedTilesetPackLoader )
