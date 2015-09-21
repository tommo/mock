module 'mock'
--------------------------------------------------------------------
--for object animator track creation
local CustomAnimatorTrackTypes = {}
local CommonCustomAnimatorTrackTypes = {}

function registerCommonCustomAnimatorTrackType( id, clas )
	CommonCustomAnimatorTrackTypes[ id ] = clas
end

function registerCustomAnimatorTrackType( objClas, id, clas )
	assert( objClas )
	assert( clas )
	local reg = CustomAnimatorTrackTypes[ objClas ]
	if not reg then
		reg = {}
		CustomAnimatorTrackTypes[ objClas ] = reg
	end
	reg[id] = clas
end


local function _collectCustomAnimatorTrackTypes( clas, collected )
	local super = clas.__super
	if super then
		_collectCustomAnimatorTrackTypes( super, collected )
	end
	local reg = CustomAnimatorTrackTypes[ clas ]
	if reg then
		for k, v in pairs( reg ) do
			collected[ k ] = v
		end
	end
end

function getCustomAnimatorTrackTypes( objClas )
	local collected = {}
	_collectCustomAnimatorTrackTypes( objClas, collected )
	for k, v in pairs( CommonCustomAnimatorTrackTypes ) do
		collected[ k ] = v
	end
	return collected
end

function getCustomAnimatorTrackTypesForObject( obj )
	local clas = obj.__class
	return getCustomAnimatorTrackTypes( clas )
end 

local function _hasCustomAnimatorTrack( clas )
	if next( CommonCustomAnimatorTrackTypes ) then return true end
	local super = clas.__super
	if super then
		if _hasCustomAnimatorTrack( super ) then
			return true
		end
	end
	local reg = CustomAnimatorTrackTypes[ clas ]
	return reg and true or false
end

function hasCustomAnimatorTrack( objClas )
	return _hasCustomAnimatorTrack( objClas )
end

function objectHasAnimatorTrack( obj )
	local clas = obj.__class
	return hasCustomAnimatorTrack( clas )
end

