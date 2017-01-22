module 'mock'

--------------------------------------------------------------------
local enumInfoCache = {}

local function getEnumInfo( enum )
local info = enumInfoCache[ enum ]
	if not info then
		local names = {}
		local v2i = {}
		local i2v = {}
		for i, entry in ipairs( enum ) do
			names[ i ] = entry[ 1 ]
			i2v[ i ] = entry[ 2 ]
			v2i[ entry[2] ] = i
		end
		info = {
			names = names,
			v2i = v2i,
			i2v = i2v,
			count = #enum
		}
		enumInfoCache[ enum ] = info
	end
	return info
end

local function fieldEditorEnum( gui, obj, field, label )
	local enum = field.__enum
	if not enum then return end
	local info = getEnumInfo( enum )
	local value = field:getValue( obj )
	local idx = value and info.v2i[ value ] or 1
	local changed, idx = gui.Combo( label, idx, info.names, info.count )
	if changed then
		field:setValue( obj, info.i2v[ idx ] )
	end
end

local function fieldEditorAsset( gui, obj, field, label )
	--TODO
	gui.LabelText( label, field:getValue( obj ) or '<none>' )
end

local function fieldEditorBoolean( gui, obj, field, label  )
	local value = field:getValue( obj )
	local changed, newValue = gui.Checkbox( label, value and true or false )
	if changed then
		field:setValue( obj, newValue )
	end
end

local function fieldEditorInt( gui, obj, field, label  )
	local value = field:getValue( obj )
	local changed, newValue = gui.InputInt( label, value or 0 )
	if changed then
		field:setValue( obj, newValue )
	end
end

local function fieldEditorFloat( gui, obj, field, label, dim )
	local step     = field:getMeta( 'step', 1 )
	local decimals = field:getMeta( 'decimals', 4 )
	local value = field:getValue( obj )
	local changed, newValue = gui.InputFloat( label, value or 0, step, step*10, decimals )
	if changed then
		field:setValue( obj, newValue )
	end
end

local function fieldEditorString( gui, obj, field, label  )
	local value = field:getValue( obj )
	local changed, newValue = gui.InputText( label, value or '', 4096 )
	if changed then
		field:setValue( obj, newValue )
	end
end


local function fieldEditorColor( gui, obj, field, label )
	local r,g,b,a = field:getValue( obj )
	local changed, r,g,b,a = gui.ColorEdit4( label, r,g,b,a )
	if changed then
		field:setValue( obj, r,g,b,a )
	end
end

local function fieldEditorVec2( gui, obj, field, label, dim )
	local step     = field:getMeta( 'step', 1 )
	local decimals = field:getMeta( 'decimals', 4 )
	local x, y = field:getValue( obj )
	local changed, x, y = gui.InputFloat2( label, x or 0, y or 0, step, step*10, decimals )
	if changed then
		field:setValue( obj, x, y )
	end
end


local function fieldEditorVec3( gui, obj, field, label, dim )
	local step     = field:getMeta( 'step', 1 )
	local decimals = field:getMeta( 'decimals', 4 )
	local x, y, z = field:getValue( obj )
	local changed, x, y, z = gui.InputFloat3( label, x or 0, y or 0, z or 0, step, step*10, decimals )
	if changed then
		field:setValue( obj, x, y, z )
	end
end

local function fieldEditor( gui, obj, field )
	local readonly = field:getMeta( 'readonly' )
	local id = field.__id
	local label = field.__label or id
	local ftype = field:getType()
	if ftype == 'string' then
		fieldEditorString( gui, obj, field, label )
	elseif ftype == 'int' then
		fieldEditorInt( gui, obj, field, label )
	elseif ftype == 'number' then
		fieldEditorFloat( gui, obj, field, label )
	elseif ftype == 'boolean' then
		fieldEditorBoolean( gui, obj, field, label )
	elseif ftype == '@asset' then
		fieldEditorAsset( gui, obj, field, label )
	elseif ftype == '@enum' then
		fieldEditorEnum( gui, obj, field, label )
	elseif ftype == 'color' then
		fieldEditorColor( gui, obj, field, label )
	elseif ftype == 'vec2' then
		fieldEditorVec3( gui, obj, field, label )
	elseif ftype == 'vec3' then
		fieldEditorVec3( gui, obj, field, label )
	end
end

--------------------------------------------------------------------
function DebugEditorUI.ObjectEditor( gui, obj )
	if not obj then return end
	local model = Model.fromObject( obj )
	if not model then return false end
	local fields = model:getFieldList()
	for i, field in ipairs( fields ) do
		local noEdit = field:getMeta( 'no_edit' )
		if not noEdit then
			fieldEditor( gui, obj, field )
		end
	end
end

