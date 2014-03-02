module 'mock'
--TODO: a generic anim curve & attr manager

--------------------------------------------------------------------
--Simple helpers
--------------------------------------------------------------------

-- function simpleCurveAnim()
-- 	local anim = MOAIAnim.new()
-- end

function buildSimpleRotationAnim( prop, from, to, easeMode, duration, animMode, nostart )
	easeMode = easeMode or MOAIEaseType.LINEAR
	duration = duration or 1
	local curve = MOAIAnimCurve.new()
	curve:reserveKeys( 2 )
	curve:setKey( 1, 0, from, easeMode )
	curve:setKey( 2, duration, to, easeMode )
	local anim = MOAIAnim.new()
	anim:reserveLinks( 1 )
	anim:setLink( 1, curve, prop, MOAIProp.ATTR_Z_ROT )
	anim:setMode( animMode or MOAITimer.NORMAL )	
	if not nostart then anim:start() end
	return anim
end
