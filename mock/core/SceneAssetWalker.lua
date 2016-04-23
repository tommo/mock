module 'mock'

--------------------------------------------------------------------
--[[
	
]]
--------------------------------------------------------------------
local function _defaultCollector( obj, field, value, collected )
	collected[ value ] = true
end

local function _collectAssetFromObject( obj, collected, collector )
	collector = collector or _defaultCollector
	local model = Model.fromObject( obj )
	if not model then return end
	local fields = model:getFieldList( true )
	for i, field in ipairs( fields ) do
		if field.__type == '@asset' then
			local value = field:getValue( obj )
			if value then
				collector( obj, field, value, collected )
			end
		end
	end
end

local function _collectAssetFromEntity( ent, collected, collector )
	_collectAssetFromObject( ent, collected, collector )
	for com in pairs( ent.components ) do
		_collectAssetFromObject( com, collected, collector )
	end
end


--------------------------------------------------------------------
local function _dependencyCollector( obj, field, value, collected )
	local meta = field.__meta
	collected[ value ] = meta and meta[ 'preload' ] and 'preload' or 'dep'
end

function collectAssetFromObject( obj, collected, collector )
	collected = collected or {}
	_collectAssetFromObject( obj, collected, collector or _defaultCollector )
	return collected
end

function collectAssetFromEntity( ent, collected, collector )
	collected = collected or {}
	_collectAssetFromEntity( ent, collected, collector or _defaultCollector )
	return collected
end

function collectSceneAssetDependency( scn )
	local collected = {}
	for ent in pairs( scn.entities ) do
		_collectAssetFromEntity( ent, collected, _dependencyCollector )
	end
	return collected
end
