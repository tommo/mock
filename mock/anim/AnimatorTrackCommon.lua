module 'mock'

--------------------------------------------------------------------
CLASS: AnimatorTrackAttr ( AnimatorTrack )
	:MODEL{}

function AnimatorTrackAttr:build()
	self.curve = self:buildCurve()
end

function AnimatorTrackAttr:onLoad( trackContext )

end


--------------------------------------------------------------------
CLASS: AnimatorTrackValue ( AnimatorTrack )
	:MODEL{}



--------------------------------------------------------------------
CLASS: AnimatorTrackEvent ( AnimatorTrack )
	:MODEL{}

