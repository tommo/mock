module 'mock'
--------------------------------------------------------------------
CLASS: CustomAnimatorTrack ( AnimatorTrack )

function CustomAnimatorTrack:initFromObject( obj, relativeTo )	
	local path  = AnimatorTargetPath.buildFor( obj, relativeTo )
	self:setTargetPath( path )
	self:onInit()
end

function CustomAnimatorTrack:onInit()
end

function CustomAnimatorTrack:isPlayable()
	return true
end

function CustomAnimatorTrack:toString()
	return 'custom track'
end

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
	for k,v in pairs( CommonCustomAnimatorTrackTypes ) do
		collected[ k ] = v
	end
	return collected
end

function getCustomAnimatorTrackTypesForObject( obj )
	local clas = obj.__class
	return getCustomAnimatorTrackTypes( clas )
end 

local function _hasCustomAnimatorTrack( clas )
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

