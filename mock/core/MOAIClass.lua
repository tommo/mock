--[[
	Convert MOAI Class into MOCK class, so that we can use our  model system on MOAI Objects
]]

--inject class into mt
-- for key, clas in pairs( _G ) do
-- 	if type( key ) == 'string' and key:startWith('MOAI') then
-- 		local getInterfaceTable = clas.getInterfaceTable
-- 		if getInterfaceTable then
-- 			local mt = getInterfaceTable()
-- 			mt.__class = clas
-- 			print( key, clas )
-- 		end
-- 	end
-- end

function convertMoaiClass( clas )

end
