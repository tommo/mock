module 'character'

local function fixpath(p)
	p=string.gsub(p,'\\','/')
	return p
end

local function stripExt(p)
	return string.gsub( p, '%..*$', '' )
end

local function stripDir(p)
	p=fixpath(p)
	return string.match(p, "[^\\/]+$")
end

--------------------------------------------------------------------
CLASS: EventEffect ( CharacterActionEvent )
	:MODEL{
		Field 'effect' :asset( 'effect' );
		Field 'loop'   :boolean();
		'----';
		Field 'spineSlot'  :string() :selection( 'getSpineSlotList' );
		Field 'followSlot' :boolean();
		'----';
		Field 'loc' :type('vec3') :getset('Loc');
		Field 'rot' :type('vec3') :getset('Rot');
	}

function EventEffect:__init()
	self.name   = 'effect'
	self.loop   = false
	self.effect = false
	self.followSlot = false
	self.spineSlot = false
	self.transform = MOAITransform.new()
end

function EventEffect:getSpineSlotList()
	local result = {
		{ '<none>', false }
	}
	local config = self:getRootConfig()
	local spinePath = config:getSpine()
	local spineData = mock.loadAsset( spinePath )
	if not spineData then return nil end
	for k,i in pairs( spineData._slotTable ) do
		table.insert( result, { k, k } )
	end
	return result
end

function EventEffect:setLoc( x,y,z )
	return self.transform:setLoc( x,y,z )
end

function EventEffect:getLoc()
	return self.transform:getLoc()
end

function EventEffect:setRot( x,y,z )
	return self.transform:setRot( x,y,z )
end

function EventEffect:getRot()
	return self.transform:getRot()
end

function EventEffect:isResizable()
	return true
end

function EventEffect:start( state, pos )
	local effect = self.effect
	if effect == '' then effect = nil end
	if not self.effect then return end
	local target = state.target
	local emEnt = mock.Entity()
	local em = mock.EffectEmitter()
	emEnt:attachInternal( em )
	em:setEffect( self.effect )	
	target:getEntity():addInternalChild( emEnt )
	local transform = self.transform
	emEnt:setLoc( transform:getLoc() )
	emEnt:setRot( transform:getRot() )
	state[ self ] = emEnt
end

function EventEffect:stop( state )
	local emEnt = state[ self ]
	if not emEnt then return end
	emEnt:destroy()
end

function EventEffect:toString()
	if not self.effect then return '<nil>' end
	local name = stripExt( stripDir( self.effect ) )
	return self.loop and '<loop>'..name or name
end


--------------------------------------------------------------------
CLASS: TrackEffect ( CharacterActionTrack )
	:MODEL{
		Field 'layer'     :type('layer')  :no_nil();
}

function TrackEffect:__init()
	self.name  = 'fx'
	self.layer = false
end

function TrackEffect:getType()
	return 'effect'
end

function TrackEffect:createEvent()
	return EventEffect()
end

function TrackEffect:toString()
	return '<fx>' .. tostring( self.name )
end

--------------------------------------------------------------------
registerCharacterActionTrackType( 'Effect', TrackEffect )
