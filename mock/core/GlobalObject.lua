module 'mock'

local GlobalObjectRegistry = {}
--------------------------------------------------------------------
CLASS: GlobalObjectNode ()
	:MODEL{
		Field '_folded' :boolean() :no_edit(); 

		Field 'name' :string() :set( 'setName' ); 
		Field 'priority' :int();
	}

function GlobalObjectNode:__init()
	self.children = {}
	self.name = self:getClassName()
	self.type     = false
	self.object   = false
	self.priority = 0
	self._folded  = false
end

function GlobalObjectNode:addNode( name, child )
	local child = child or GlobalObjectNode()
	child.parent   = self
	child.library  = self.library
	child:setName( name )
	return child
end

function GlobalObjectNode:setName( name )
	--build fullpath for object	
	--TODO: rename object if duplicated name found
	local parent = self.parent
	if self.name then
		parent.children[ self.name ] = nil
	end
	self.name = name
	parent.children[ name ] = self
	self:updateFullName()
end

function GlobalObjectNode:updateFullName()
	local name = self.name
	local parent = self.parent
	if self.fullName then
		self.library.index[ self.fullName ] = nil
	end
	self.fullName = parent.fullName and ( parent.fullName .. '.' .. name ) or name
	self.library.index[ self.fullName ] = self
	for k, obj in pairs( self.children ) do
		obj:updateFullName()
	end
end

function GlobalObjectNode:addGroup( name )
	local node = self:addNode( name )
	node.type = 'group'
	return node
end

function GlobalObjectNode:addObject( name, object )
	local node = self:addNode( name )
	node.type     = 'object'
	node.object   = object
	node.objectType = object:getClassName()
	return node
end

function GlobalObjectNode:removeNode( name )
	local n = self.children[ name ]
	if n then
		n.parent = false
		self.children[ name ] = nil
		return true
	end
	return false
end

function GlobalObjectNode:reparent( obj )
	if self.parent then
		self.parent.children[ self.name ] = nil
	end
	obj:addNode( self.name, self )
end

function GlobalObjectNode:save()
	local tt = self.type
	if tt == 'group' then
		local children = {}
		for name, child in pairs( self.children ) do
			children[ name ] = child:save()
		end
		return {
			name   = self.name,
			children = children,
			type   = 'group'
		}
	else
		return {
			name   = self.name,
			object = serialize( self.object ),
			type   = 'object'
		}
	end
end

function GlobalObjectNode:loadGroup( data )
	for name ,childData in pairs( data['children'] ) do
		local tt   = childData['type']
		if tt == 'group' then
			local node = self:addGroup( name )
			node:loadGroup( childData )
		else
			local node = self:addNode( name )
			node:loadObject( childData )
		end
	end
end

function GlobalObjectNode:loadObject( data )
	local tt = data['type']
	assert( tt == 'object' )
	self.type = 'object'

	local object = deserialize( nil, data['object'] )
	self.object = object
	self.objectType = object:getClassName()
end

---------------------------------------------------------------------
CLASS: GlobalObjectLibrary ()
	:MODEL{}

function GlobalObjectLibrary:__init()
	self.index = {}
	
	local root    = GlobalObjectNode()
	root.type     = 'group'
	root.library  = self
	root.fullName = false

	self.root  = root
end

function GlobalObjectLibrary:load( data )
	if not data then return end
	return self.root:loadGroup( data )
end

function GlobalObjectLibrary:save()
	return self.root:save()
end

function GlobalObjectLibrary:get( path )
	local n = self:getNode( path )
	if not n then return nil end
	return n.object
end

function GlobalObjectLibrary:getNode( path )
	return self.index[ path ]
end

local function _collectChildNode( node, list )
	for k, n in pairs( node.children ) do
		table.insert( list, n )
		_collectChildNode( n, list )
	end
	return list
end

function GlobalObjectLibrary:getNodeList()
	local list = {}
	_collectChildNode( self.root, list )
	return list
end



--------------------------------------------------------------------
function registerGlobalObject( name, clas ) --TODO:icon?
	if GlobalObjectRegistry[ name ] then
		_warn( 'global object class duplicated', clas )
	end
	GlobalObjectRegistry[ name ] = clas
end

function getGlobalObjectClass( name )
	return GlobalObjectRegistry[ name ]
end

function getGlobalObjectClassRegistry()
	return GlobalObjectRegistry
end


--------------------------------------------------------------------
local _globalObjectLibrary = GlobalObjectLibrary()
function getGlobalObjectLibrary()
	return _globalObjectLibrary
end

function getGlobalObject( id )
	return _globalObjectLibrary:get( id )
end

