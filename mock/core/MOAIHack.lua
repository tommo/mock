
--------------------------------------------------------------------
--workaround for listing mounted archive file
--------------------------------------------------------------------
local _listFiles = MOAIFileSystem.listFiles
local insert = table.insert
MOAIFileSystem.listFiles = function( path )
	local result = _listFiles( path ) 
	if result then
		local output = {}
		for i, file in ipairs( result ) do
			if not file:match( '^%._' ) then
				insert( output, file )
			end
		end
		return output
	else
		return result
	end
end

--------------------------------------------------------------------
--workaround
--------------------------------------------------------------------
if MOAIEnvironment.osBrand == 'Windows' then 
	local _computeBounds = MOAIGfxBuffer:getInterfaceTable().computeBounds
	injectMoaiClass( MOAIGfxBuffer, {
		computeBounds = function( self, ... )
			local x0, y0, z0, x1, y1, z1 = _computeBounds( self, ... )
			return z0, y0, x0, z1, y1, x1
		end
		}
	)
end
