module 'mock'
--------------------------------------------------------------------
CLASS: AnimatorTrackAttr ( AnimatorTrack )
	:MODEL{}

function AnimatorTrackAttr:__init()
	self.name = 'attr'
	self.targetAttrId = false
	self.asDelta = true
end

function AnimatorTrackAttr:getType()
	return 'attr'
end

function AnimatorTrackAttr:createKey()
	return AnimatorKeyNumber()
end

function AnimatorTrackAttr:toString()
	return '<num>' .. tostring( self.name )
end

function AnimatorTrackAttr:build( context )
	self.curve = assert( self:buildCurve() )
end

function AnimatorTrackAttr:onStateLoad( state, context )
	local target = state.target:getProp() --TODO:real target
	state:addAttrLink( self, self.curve, target, self.targetAttrId, self.asDelta )
end

function AnimatorTrackAttr:isPlayable()
	return true
end


