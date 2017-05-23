module 'mock'

registerGlobalSignals{
	'locale.change',
	'locale.update',
}

local _LocaleManager

function getLocaleManager()
	return _LocaleManager
end

function translate( categoryId, stringId, ... )
	return _LocaleManager:translate( categoryId, stringId, ... )
end

function getLocaleId()
	return _LocaleManager:getLocaleId()
end

--------------------------------------------------------------------
CLASS: LocaleManager ( GlobalManager )
	:MODEL{}

function LocaleManager:__init()
	_LocaleManager = self
	self.localeConfigMap = {}
	self.defaultLocaleId = 'en'
	self.activeLocaleId = 'en'
	self.activeLocaleConfig = false
end

function LocaleManager:translate( categoryId, stringId, ... )
	local localeConfig = self.activeLocaleConfig
	if not localeConfig then
		_warn( 'no active localeConfig' )
		return stringId
	end
	return localeConfig:translate( categoryId, stringId, ... )
end

function LocaleManager:getActiveLocale()
	return self.activeLocaleId
end

function LocaleManager:getLocaleConfig( id, fallback )
	local localeConfig = self.localeConfigMap[ id ]
	if not localeConfig and fallback then
		localeConfig = self.localeConfigMap[ fallback ]
	end
	return localeConfig
end

function LocaleManager:affirmLocale( id )
	local localeConfig = self.localeConfigMap[ id ]
	if not localeConfig then
		localeConfig = LocaleConfig()
		localeConfig.id = id
		self.localeConfigMap[ id ] = localeConfig
	end
	return localeConfig
end

local locales = {
	'en',
	'cn',
	'jp',
	'fr',
	'it'
}

local function matchLocaleName( s )
	for i, k in ipairs( locales ) do
		if k == s then
			return k
		end
	end
	return nil
end

function LocaleManager:loadStringMap( categoryId, path )
	local assetType = getAssetType( path )
	if not assetType then
		_warn( 'failed loading string map', path )
		return false
	end
	if assetType == 'data_sheet' then
		local sheet = loadAsset( path )
		for i, row in pairs( sheet ) do
			local id = row[ 'id' ]
			if id then
				for k, v in pairs( row ) do
					if v:trim() == '' then v = nil end
					local localeName = v and matchLocaleName( k )
					if localeName then
						local localeConfig = self:affirmLocale( localeName )
						localeConfig:addString( categoryId, id, v )
					end
				end
			end
		end
	else
		_warn( 'unknown string map asset type', path, assetType )
		return false
	end

	return true
end

function LocaleManager:setActiveLocale( id )
	self.activeLocaleId = id
	local localeConfig = self:getLocaleConfig( id )
	if not localeConfig then
		_error( 'no localeConfig found', id )
		return false
	end
	self.activeLocaleConfig = localeConfig
	emitGlobalSignal( 'locale.change', id )
	return true
end

--------------------------------------------------------------------
CLASS: LocaleConfig ()
	:MODEL{}

function LocaleConfig:__init()
	self.id = 'en'
	self.stringCategories = {}
end

function LocaleConfig:getId()
	return self.id
end

function LocaleConfig:affirmCategory( id )
	local cat = self.stringCategories[ id ]
	if not cat then
		cat = {}
		self.stringCategories[ id ] = cat
	end
	return cat
end

function LocaleConfig:translate( categoryId, stringId, ... )
	local category = self.stringCategories[ categoryId or 'main' ]
	local s = category and category[ stringId ]
	if not s then
		_warn( 'no string found in locale', stringId, self.id )
		return stringId
	end
	return s
end

function LocaleConfig:addString( categoryId, id, value )
	local category = self:affirmCategory( categoryId or 'main' )
	-- print( 'adding string', self.id, categoryId, id, value )
	category[ id ] = value
end


--------------------------------------------------------------------
LocaleManager()