module 'mock'
--------------------------------------------------------------------
CLASS: Prefab ()

function Prefab:__init( data )
	self.data = data
end

function Prefab:createInstance()
	local data = self.data
	if not data.body then
		_stat('loading empty prefab')
		return Entity()
	end
	return deserializeEntity( data )
end

--------------------------------------------------------------------
function PrefabLoader( node )
	local path = node:getObjectFile( 'def' )
	local data = loadAssetDataTable( path )
	return Prefab( data )	
end

registerAssetLoader( 'prefab',  PrefabLoader )
