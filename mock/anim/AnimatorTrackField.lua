module 'mock'
-- --------------------------------------------------------------------
-- CLASS: AnimatorTrackFieldParentObject ( AnimatorTrackGroup )
--------------------------------------------------------------------
CLASS: AnimatorTrackField ( AnimatorTrack )
	:MODEL{
		Field 'fieldId' :string();
	}

function AnimatorTrackField:__init()
	self.name = 'field'
	self.targetField = false
	self.fieldId = ''
end

function AnimatorTrackField:initFromObject( obj, fieldId, relativeTo )
	local path  = AnimatorTargetPath.buildFor( obj, relativeTo )
	local model = Model.fromObject( obj )
	self.targetField = model:getField( fieldId )
	self.fieldId = fieldId
	self:setTargetPath( path )
end

function AnimatorTrackField:isMatched( obj, fieldId, relativeTo )
	return self.targetPath:get( relativeTo ) == obj and fieldId == self.fieldId
end

function AnimatorTrackField:getType()
	return 'field'
end

function AnimatorTrackField:createKey()
	local key = AnimatorKeyNumber()
	return key
end

function AnimatorTrackField:getTargetValue( obj )
	return self.targetField.getValue( obj )
end

function AnimatorTrackField:toString()
	local pathText = self.targetPath:toString()
	return pathText..'::'..self.fieldId
end

function AnimatorTrackField:apply( state, target, t )
	local value = self.curve:getValueAtTime( t )
	return self.targetField:setValue( target, value )
end

function AnimatorTrackField:build( context ) --building shared data
	self.curve = self:buildCurve()
	context:updateLength( self:calcLength() )
end

function AnimatorTrackField:isPlayable()
	return true
end

function AnimatorTrackField:onStateLoad( state )
	local target = state:findTarget( self.targetPath )
	state:addUpdateListenerTrack( self, target )
end

function AnimatorTrackField:onLoad()
	local clas = self.targetPath:getTargetClass()
	local model = Model.fromClass( clas )
	self.targetField = assert(model:getField( self.fieldId ) )
end
