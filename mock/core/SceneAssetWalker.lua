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
	for child in pairs( ent.children ) do
		_collectAssetFromEntity( child, collected, collector )
	end
end


--------------------------------------------------------------------
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

function collectAssetFromGroup( group, collected, collector )
	collected = collected or {}
	collector = collector or _defaultCollector
	for ent in pairs( group.entities ) do
		_collectAssetFromEntity( ent, collected, collector )
	end
	for childGroup in pairs( group.childGroups ) do
		collectAssetFromGroup( childGroup, collected, collector )
	end
	return collected
end

function collectAssetFromScene( scn, collected, collector )
	collected = collected or {}
	collector = collector or _defaultCollector
	for ent in pairs( scn.entities ) do
		if not ent.parent then
			_collectAssetFromEntity( ent, collected, collector )
		end
	end
	return collected
end


--------------------------------------------------------------------
local function _dependencyCollector( obj, field, value, collected )
	local meta = field.__meta
	local preloadMeta = meta and meta[ 'preload' ]
	local v0 = collected[ value ]
	local v1 = preloadMeta and 'preload' or 'dep'
	if v1 == v0 then return end
	if v0 == 'preload' then
		--do nothing
	else
		collected[ value ] = v1
	end
end


function collectGroupAssetDependency( group, collected )
	return collectAssetFromGroup( group, collected, _dependencyCollector )
end
