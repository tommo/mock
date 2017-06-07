module 'mock'

SimpleShakeAnimations = {}

function SimpleShakeAnimations.xyz( entity, dx, dy, dz, duration )
	local coro = MOAICoroutine.new()
	duration = duration or 0.5
	dx = dx or 0
	dy = dy or 0
	dz = dz or 0
	coro:run( function()
		local elapsed = 0
		local px, py, pz = entity:getPiv()
		local sx, sy, sz = randsign(), randsign(), randsign()
		while true do
			local dt = coroutine.yield()
			elapsed = elapsed + dt
			local k = elapsed/ duration
			if k >= 1 then break end
			local k1 = 1 - k
			entity:setPiv( sx*dx*k1+px, sy*dy*k1+py, sz*dz*k1+pz )
			sx = - sx
			sy = - sy
			sz = - sz
		end
		entity:setPiv( px, py, pz )
	end )
	return coro
end
