--[[
* MOCK framework for Moai

* Copyright (C) 2012 Tommo Zhou(tommo.zhou@gmail.com).  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining
* a copy of this software and associated documentation files (the
* "Software"), to deal in the Software without restriction, including
* without limitation the rights to use, copy, modify, merge, publish,
* distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to
* the following conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local setmetatable  = setmetatable
local getmetatable  = getmetatable

local rawget, rawset = rawget, rawset
--------------------------------------------------------------------
-- CLASS
--------------------------------------------------------------------
local newclass
local globalClassRegistry = {}

local reservedMembers = {
	['__init']  = true,
	['__name']  = true,
	['__env']   = true,
	['__model'] = true,
}

local BaseClass = {
	__subclasses={}
}

_BASECLASS = BaseClass --use this to extract whole class tree

--Class build DSL
function BaseClass:MODEL( t )
	local m = Model( self )
	m:update( t )
	return self
end

function BaseClass:MEMBER( t )
	for k, v in pairs( t ) do
		self[k] = v
	end
	return self
end

function BaseClass:META( t )
	self.__meta = t
	return self
end

function BaseClass:rawInstance( t )
	return setmetatable( t, self )
end

function BaseClass:isSubclass( superclass )
	local s = self.__super
	while s do
		if s == superclass then return true end
		s = s.__super
	end
	return false
end

--Instance Method
function BaseClass:getClass()
	return self.__class
end

function BaseClass:getClassName()
	return self.__class.__name
end

function BaseClass:getClassFullName()
	return self.__class.__fullname
end

function BaseClass:isInstance( clas )
	local c = self.__class
	if c == clas then return true end
	return c:isSubclass( clas )
end

-- function BaseClass:callSuperMethod( name, ... )
-- 	local m = self[ name ]
-- 	local super = self.__super
-- 	while super do
-- 		local m1 = super[ name ]
-- 		if not m1 then break end
-- 		if m1 ~= m then 
-- 			return m1( self, ... ) end
-- 		super = super.__super
-- 	end
-- 	error( 'no super method: '.. name, 2 )
-- end


--------------------------------------------------------------------
local function buildInitializer(class,f)
	if not class then return f end
	local init=rawget(class,'__init')
	
	if type(init)=='table' then --copy
		local t1=init
		init=function(a)
			for k,v in pairs(t1) do
				a[k]=v
			end
		end
	end

	if init then
		if f then
			local f1=f
			f=function(a,...)
				init(a,...)
				return f1(a,...)
			end
		else
			f=init
		end
	end

	return buildInitializer(class.__super,f)
end

local function buildInstanceBuilder(class)
	local init=buildInitializer(class)
	local newinstance

	if init then
		newinstance=function (t,...)
			local o=setmetatable({}, class)
			init(o,...)
			return o
		end
	else
		newinstance=function (t)
			return setmetatable({}, class)
		end
	end

	local mt=getmetatable(class)
	mt.__call=newinstance

	for s in pairs(class.__subclasses) do
		buildInstanceBuilder(s)
	end
end

--------------------------------------------------------------------
function newclass( b, superclass, name  )		
	b=b or {}
	local index
	superclass = superclass or BaseClass
	b.__super  = superclass

	for k,v in pairs(superclass) do --copy super method to reduce index time
		if not reservedMembers[k] and rawget(b,k)==nil then 
			b[k]=v
		end
	end

	superclass.__subclasses[b] = true

	b.__index = b
	b.__class = b
	b.__subclasses = {}
	if not name then
		local s = superclass
		while s do
			local sname = s.__name
			if sname and sname ~= '??' then
				name = s.__name..':??'
				break
			end
			s = s.__super
		end
	end
	b.__name  = name or '??'


	local newindex=function( t, k, v )		
		rawset( b, k, v )
		if k=='__init' then
			buildInstanceBuilder(b)
		else --spread? TODO
		end
	end
	
	setmetatable( b, {
			__newindex = newindex,
			__isclass  = true
		}
	)

	buildInstanceBuilder(b)
	if superclass.__initclass then
		superclass:__initclass( b )
	end
	return b
end

function updateAllSubClasses( c, force )
	for s in pairs(c.__subclasses) do
		local updated = false
		for k,v in pairs(c) do
			if not reservedMembers[k] and ( force or rawget( s, k ) == nil ) then 
				updated = true
				s[k] = v
			end
		end
		if updated then updateAllSubClasses(s) end
	end
end

function isClass( c )
	local mt = getmetatable( c )
	return mt and mt.__isclass or false
end

function isClassInstance( o )
	return getClass( o ) ~= nil
end

function isInstanceOf( o, clas )
	return isClassInstance(o) and o:isInstance( clas )
end

function getClass( o )
	if type( o ) ~= 'table' then return nil end
	local clas = getmetatable( o )
	if not clas then return nil end
	local mt = getmetatable( clas )
	return mt and mt.__isclass and clas or nil
end

local classBuilder
local function affirmClass( t, id )
	if type(id) ~= 'string' then error('class name expected',2) end

	return function( a, ... )
			local superclass
			if select( '#', ... ) >= 1 then 
				superclass = ...
				if not superclass then
					error( 'invalid superclass for:' .. id, 2 )
				end
			end
			
			if a ~= classBuilder then
				error( 'Class syntax error', 2 )
			end
			if superclass and not isClass( superclass ) then
				error( 'Superclass expected, given:'..type( superclass ), 2)
			end
			local clas = newclass( {}, superclass, id )
			local env = getfenv( 2 )
			env[id] = clas
			if env ~= _G then
				local prefix = env._NAME or tostring( env )
				clas.__fullname = prefix .. '.' .. clas.__name
			else
				clas.__fullname = clas.__name
			end
			clas.__env = env

			if globalClassRegistry[ clas.__fullname ] then
				_error( 'duplicated class:', clas.__fullname )
				print( debug.traceback(2) )
			end
			globalClassRegistry[ clas.__fullname ] = clas
			return clas
		end

end

classBuilder = setmetatable( {}, { __index = affirmClass } )
_G.CLASS  = classBuilder

function findClass( term )
	local l = #term
	for n, clas in pairs( globalClassRegistry ) do		
		if string.find( n, term, -l ) then return clas end
	end
	return nil
end

--------------------------------------------------------------------
--MODEL & Field
--------------------------------------------------------------------

CLASS: Model ()
function Model:__init( clas, clasName )
	self.__class = clas
	self.__name  = clas.__fullname or clasName or 'LuaObject'
	rawset( clas, '__model', self )
end

function Model.fromObject( obj )
	local clas = getClass( obj )
	-- if not clas then return nil end
	assert( clas, 'not class object' )
	return Model.fromClass( clas )
end

function Model.fromClass( clas )
	if not isClass(clas) then
		return nil
	end
	--TODO:support moai class
	local m = rawget( clas, '__model' )
	if not m then
		-- print( 'create model for', clas.__name )
		m = Model( clas )
	end
	assert( m.__name == clas.__fullname )
	return m	
end

function Model.find( term )
	local clas = findClass( term )
	return clas and Model.fromClass( clas ) or nil
end

function Model.findName( term )
	local m = Model.find( term )
	return m and m.__name or nil
end

function Model.fromName( fullname )
	local clas = globalClassRegistry[ fullname ]
	if clas then return Model.fromClass( clas ) end
	return nil
end

function Model:__call( body )
	self:update( body )
	return self
end

function Model:getName()
	return self.__name
end

function Model:update( body )
	--body[1] = name
	-- local name = body[1]
	-- if type(name) ~= 'string' then error('Model Name should be the first item', 3 ) end
	-- self.__name = name
	local fields = {}
	local fieldN = {}
	for i = 1, #body do
		local f = body[i]
		if getmetatable( f ) ~= Field then 
			error('Field expected in Model, given:'..type( f ), 3)
		end
		local id = f.__id
		if fieldN[id] then error( 'duplicated Field:'..id, 3 ) end
		fieldN[ id ] = f
		fields[ i ] = f
		f.__model = self
	end
	self.__fields = fields
	self.__fieldNames = fieldN
	-- self.__class.__name = name
	return self
end

function Model:getMeta()
	return rawget( self.__class, '__meta' )
end


function Model:getField( name, findInSuperClass )
	local fields = self.__fields
	if fields then 
		for i, f in ipairs( self.__fields ) do
			if f.__id == name then return f end
		end
	end
	findInSuperClass = findInSuperClass~=false
	if findInSuperClass then
		local superModel = self:getSuperModel()
		if superModel then return superModel:getField( name, true ) end
	end
	return nil
end

local function _collectFields( model, includeSuperFields, list, dict )
	list = list or {}
	dict = dict or {}
	if includeSuperFields then
		local s = model:getSuperModel()
		if s then _collectFields( s, true, list, dict ) end
	end
	local fields = model.__fields
	if fields then
		for i, f in ipairs( fields ) do
			local id = f.__id
			local i0 = dict[id]
			if i0 then --override
				list[i0] = f
			else
				local n = #list
				list[ n + 1 ] = f
				dict[ id ] = n + 1
			end
		end
	end
	return list
end

function Model:getFieldList( includeSuperFields )
	return _collectFields( self, includeSuperFields ~= false )
end


local function _collectMeta( clas, meta )
	meta = meta or {}
	local super = clas.__super
	if super then
		_collectMeta( super, meta )
	end
	local m = rawget( clas, '__meta' )
	if not m then return meta end
	for k, v in pairs( m ) do
		meta[ k ] = v
	end
	return meta
end

function Model:getCombinedMeta()
	return _collectMeta( self.__class )
end


function Model:getSuperModel( name )
	local superclass = self.__class.__super
	if not superclass then return nil end
	local m = rawget( superclass, '__model' )
	if not m then
		m = Model( superclass )
	end
	return m
end

function Model:getClass()
	return self.__class
end

function Model:newInstance( ... )
	local clas = self:getClass()
	return clas( ... )
end

function Model:isInstance( obj )
	if type(obj) ~= 'table' then return false end
	local clas = getmetatable( obj )
	local clas0 = self.__class
	while clas do
		if clas == clas0 then return true end
		clas = rawget( clas, '__super' )
	end
	return false
end

function Model:getFieldValue( obj, name )
	if not self:isInstance( obj ) then return nil end
	local f = self:getField( name )
	if not f then return nil end
	return f:getValue( obj )
end

function Model:setFieldValue( obj, name, ... )
	if not self:isInstance( obj ) then return nil end
	local f = self:getField( name )
	if not f then return nil end
	return f:setValue( obj, ... )
end

--------------------------------------------------------------------
CLASS: Field ()
function Field:__init( id )
	self.__id       = id
	self.__type     = 'number'
	self.__getter   = true 
	self.__setter   = true
	self.__objtype  = false
end

function Field:type( t )
	self.__type = t
	return self
end

function Field:array( t ) 
	self.__type     = '@array'
	self.__itemtype = t or 'number'
	return self
end

function Field:collection( t ) 
	self.__type     = '@array'
	self.__itemtype = t or 'number'
	self:meta{ ['collection'] = true }
	return self
end

function Field:enum( t )
	self.__type  = '@enum'
	self.__enum  = t
	return self
end

function Field:table( ktype, vtype ) 
	self.__type    = v
	self.__keytype = ktype
	return self
end

function Field:asset( assetType )
	self.__type      = '@asset'
	self.__assettype = assetType
	return self
end

--type shortcut
function Field:number()
	return self:type('number')
end

function Field:boolean()
	return self:type('boolean')
end

function Field:string()
	return self:type('string')
end

function Field:int()
	return self:type('int')
end

function Field:no_nil()
	return self:meta { no_nil = true } --will get validated against onStart
end

---
function Field:label( l )
	self.__label = l
	return self
end

function Field:meta( meta )
	assert( type(meta) == 'table', 'metadata should be table' )
	local meta0 = self.__meta or {} --copy into old meta
	for k, v in pairs( meta ) do
		meta0[k] = v
	end
	self.__meta = meta0
	return self
end

function Field:sub()
	self.__objtype = 'sub'
	return self
end

function Field:ref()
	self.__objtype = 'ref'
	return self
end

function Field:no_edit() --short cut
	return self:meta{ no_edit = true }
end

function Field:no_save() --short cut
	return self:meta{ no_save = true }
end

function Field:readonly() --short cut
	return self:meta{ readonly = true }
end

function Field:range( min, max )
	if min then self:meta{ min = min } end
	if max then self:meta{ max = max } end
	return self
end

function Field:get( getter )
	if type(getter) == 'string' then
		local getterName = getter
		getter = function( obj )
			local f = obj[getterName]
			if f then return f( obj ) else error( 'getter not found:'..getterName ) end
		end
	end
	self.__getter = getter
	return self
end

function Field:set( setter )
	if type(setter) == 'string' then
		local setterName = setter
		setter = function( obj, ... )
			local f = obj[setterName]
			if f then return f( obj, ... ) else error( 'setter not found:'..setterName ) end
		end
	end
	self.__setter = setter
	return self
end

function Field:getset( fieldName )
	return self:get('get'..fieldName):set('set'..fieldName)
end

function Field:isset( fieldName )
	return self:get('is'..fieldName):set('set'..fieldName)
end

function Field:getValue( obj )
	local getter = self.__getter
	if not getter then return nil end 
	if getter == true then return obj[ self.__id ] end
	return getter( obj )
end

function Field:setValue( obj, ... )
	local setter = self.__setter
	if not setter then return end 
	if setter == true then obj[ self.__id ] = ... return end
	setter( obj, ... )
end

function Field:getIndexValue( obj, idx )
	local t = self:getValue( obj )	
	return t[idx]
end

function Field:setIndexValue( obj, idx, v )
	local t = self:getValue( obj )	
	t[idx] = v
end

function Field:getId()
	return self.__id
end

function Field:getType()
	return self.__type
end

function Field:getMeta( key, default )
	local v
	if self.__meta then 
		v= self.__meta[key]
	end
	if v == nil then return default end
	return v
end


--------------------------------------------------------------------
---CLASS Replacement?
--------------------------------------------------------------------
function findClassesFromEnv( env )
	local collected = {}
	for key , clas in pairs( globalClassRegistry )  do
		if clas.__env == env then
			collected[ key ] = clas
		end
	end
	return collected
end

function releaseClassesFromEnv( env )
	local toremove = findClassesFromEnv( env )
	for key, clas in pairs( toremove ) do
		globalClassRegistry[ key ] = nil
	end
	return toremove
end


--------------------------------------------------------------------
CLASS: MoaiModel (Model)
function MoaiModel:newinstance( ... )
	return self.__class.new()
end

