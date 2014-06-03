module 'mock'

CLASS: PrebuiltAtlasItem ()
CLASS: PrebuiltAtlasPage ()
CLASS: PrebuiltAtlas ()

PrebuiltAtlasItem
	:MODEL{
		Field 'name' :string() :no_edit();
		Field 'x' ;
		Field 'y' ;		
		Field 'w' ;
		Field 'h' ;
		Field 'ox'; --offset
		Field 'oy';
		Field 'ow'; --original
		Field 'oh';
		Field 'u0';
		Field 'v0';
		Field 'u1';
		Field 'v1';
		Field 'rotated' :boolean();		
	}

function PrebuiltAtlasItem:__init()
	self.w,  self.h  = 100, 100
	self.ow, self.oh = 100, 100
	self.x,  self.y  = 0,0
	self.ox, self.oy = 0,0
	self.rotated = false
	self.parent  = false
end

--------------------------------------------------------------------
PrebuiltAtlasPage
	:MODEL{
		Field 'id'     :int();
		Field 'source' :string() :no_edit();
		Field 'w'      :int();
		Field 'h'      :int();
		-- Field 'texture' :string() :no_edit();
		Field 'items'   :array( PrebuiltAtlasItem ) :no_edit();
	}

function PrebuiltAtlasPage:__init()
	self.id      = 0
	self.source  = false
	-- self.texture = false
	self.items   = {}
	self.parent  = false
	self.w = 100
	self.h = 100
end

function PrebuiltAtlasPage:addItem()
	local item = PrebuiltAtlasItem()
	table.insert( self.items, item )
	item.parent = self
	return item
end

function PrebuiltAtlasPage:_postLoad()
	for i, item in ipairs( self.items ) do
		item.parent = self
	end
end

--------------------------------------------------------------------
PrebuiltAtlas
	:MODEL{
		Field 'path' :string() :no_edit();
		Field 'pages' :array( PrebuiltAtlasPage ) :no_edit();
	}

function PrebuiltAtlas:__init()
	self.path  = false
	self.pages = {}
end

function PrebuiltAtlas:addPage()
	local page = PrebuiltAtlasPage()
	table.insert( self.pages, page )
	page.parent = self
	page.id = #self.pages
	return page
end

function PrebuiltAtlas:load( path )
	mock.deserializeFromFile( self, path )
	for i, page in ipairs( self.pages ) do
		page.parent = self
		page:_postLoad()
	end
end

function PrebuiltAtlas:save( path )
	return mock.serializeToFile( self, path )
end

