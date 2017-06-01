module 'mock'

--------------------------------------------------------------------
CLASS: LocalePackItem ()
	:MODEL{}

function LocalePackItem:__init()
	self.path = ''
	self.name = ''
end

function LocalePackItem:getName()
	return self.name
end

function LocalePackItem:setName( n )
	self.name = n
end

function LocalePackItem:getAssetPath()
	return self.path
end

function LocalePackItem:fromData( data )
	self.path = data[ 'path' ]
	self.name = data[ 'name' ]
end

function LocalePackItem:toData()
	local data = {}
	data[ 'path' ] = self.path
	data[ 'name' ] = self.name
	return data
end


--------------------------------------------------------------------
CLASS: LocalePack ()
	:MODEL{}

function LocalePack:__init()
	self.dataPath  = false
	self.assetPath = false
	self.items = {}
	self.data = false
	self.sourceLocale = false
	self.translationPacks = {}
	self.itemMapCache = {}
end

function LocalePack:getSourceLocale()
	return self.sourceLocale or getDefaultSourceLocale()
end

function LocalePack:addAssetItem( assetPath )
	local item0 = self:getAssetItem( assetPath )
	if item0 then
		_error( 'asset already included', assetPath )
		return false
	end
	local item = LocalePackItem()
	item.path = assetPath
	item.name = stripdir( assetPath )
	item.parentPack = self
	table.insert( self.items, item )
	self.itemMapCache = {}
	return item
end

function LocalePack:getAssetItem( assetPath )
	local cache = self.itemMapCache
	local item = cache[ assetPath ]
	if item ~= nil then return item end
	for i, it in ipairs( self.items ) do
		if it.path == assetPath then 
			item = it
			break
		end
	end
	cache[ assetPath ] = item or false
	return item
end

function LocalePack:removeItem( packItem )
	if packItem.parentPack ~= self then
		return false
	end
	local idx = table.index( self.items, packItem )
	table.remove( self.items, idx )
	packItem.parentPack = false
	self.itemMapCache = {}
	return true
end

function LocalePack:removeAssetItem( assetPath )
	local item = self:getAssetItem( assetPath )
	if not item then return false end
	return self:removeItem( item )
end

function LocalePack:getTranslationPack( locale )
	local t = self.translationPacks[ locale ]
	if t == nil then
		t = self:loadTranslationPack( locale )
	end
	return t
end

function LocalePack:loadTranslationPack( locale )
	local translationPackPath = self.dataPath .. '/' ..locale
	local translationPack = false
	if MOAIFileSystem.checkFileExists( translationPackPath ) then
		local m = loadfile( translationPackPath )
		if m then
			local ok, translationData = pcall( m )
			if ok then
				translationPack = {}
				for k, v in pairs( translationData ) do
					local i18n = I18N() --i18n object
					i18n.load{ [locale] = v }
					i18n.setLocale( locale )
					translationPack[ k ] = i18n
				end
			end
		end
	else
		_warn( 'translation data not found', translationPackPath )
	end
	self.translationPacks[ locale ] = translationPack
	return translationPack
end

function LocalePack:getAssetTranslation( locale, assetPath )
	local pack = self:getTranslationPack( locale )
	local item = self:getAssetItem( assetPath )
	if not ( pack and item ) then return nil end
	local translation = pack[ item.name ]
	return translation
end

function LocalePack:affirmData()
	if not self.dataReady then
		self:loadData()
	end
end

function LocalePack:loadData()
	if self.dataReady then return end
	self.dataReady = true
	for i, localeId in ipairs( self.locales ) do

	end
end

function LocalePack:load( configPath, dataPath )
	self.configPath = configPath
	local configData = loadAssetDataTable( configPath )
	if not configData then
		_warn( 'failed loading locale pack config', configPath )
		return false
	end
	self:loadConfig( configData )
	self.dataPath = dataPath
	self.dataReady = false
	return true
end

function LocalePack:loadConfig( configData )
	local items = {}
	for i, assetEntry in ipairs( configData[ 'items' ] or {} ) do
		local item = LocalePackItem()
		item:fromData( assetEntry )
		item.parentPack = self
		table.insert( items, item )
	end
	self.items = items
	self.itemMapCache = {}
	self.sourceLocale = configData[ 'source_locale' ]
end

function LocalePack:saveConfig()
	local config = {}
	local itemData = {}
	for i, item in ipairs( self.items ) do
		table.insert( itemData, item:toData() )
	end
	config[ 'items' ] = itemData
	config[ 'source_locale'] = self.sourceLocale
	return config
end

function LocalePack:saveConfigToFile()
	if self.configPath then
		local data = self:saveConfig()
		mock.saveJSONFile( data, self.configPath )
	end
end


--------------------------------------------------------------------
local function loadLocalePack( node )
	local pack = LocalePack()
	local configPath = node:getObjectFile( 'config' )
	local dataPath = node:getObjectFile( 'data' )
	if not pack:load( configPath, dataPath ) then return false end
	pack.assetPath = node:getPath()
	return pack
end

registerAssetLoader( 'locale_pack', loadLocalePack )