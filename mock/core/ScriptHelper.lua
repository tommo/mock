local setfenv = setfenv
local pcall   = pcall
local function loadScriptWithEnv( script )
	local innerFunc, err   = loadstring( script )
	if not innerFunc then
		return false, err		
	else
		local outputFunc = function( fenv, ... )
			setfenv( innerFunc, fenv )
			local ok, result = pcall( innerFunc, ... )
			if not ok then
				_warn( 'error running eval script', result )
				return false
			else
				return true, result
			end
		end
		return outputFunc
	end
end

local function loadEvalScriptWithEnv( exprScript )
	local valueScript = 'return '..tostring( exprScript )
	return loadScriptWithEnv( valueScript )
end

_G.loadScriptWithEnv     = loadScriptWithEnv
_G.loadEvalScriptWithEnv = loadEvalScriptWithEnv