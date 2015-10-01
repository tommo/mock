module 'mock'

--------------------------------------------------------------------
--[[
	
]]
--------------------------------------------------------------------

local function needPreload( field )
	if field.__type ~= '@asset' then return false end
	local meta = field.__meta
	return meta and meta[ 'preload' ]
end

local function collectAssetFromFields( obj, field, collected )
	if field.__type == '@asset' and field.__meta then
		local v = field:getValue( obj )
		if v then
			collected[ v ] = true
		end
	end
end

local function collectAssetFromObject( obj, collected )
	local model = Model.fromObject( obj )
	if not model then return end
	local fields = model:getFieldList( true )
	for i, field in ipairs( fields ) do
		collectAssetFromFields( obj, field, collected )
	end
end

local function collectAssetFromEntity( ent, collected )
	collectAssetFromObject( ent, collected )
	for com in pairs( ent.components ) do
		collectAssetFromObject( com, collected )
	end
end

function collectSceneAssetDependency( scn )
	local collected = {}
	for ent in pairs( scn.entities ) do
		collectAssetFromEntity( ent, collected )
	end
	return collected
end
