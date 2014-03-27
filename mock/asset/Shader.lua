module 'mock'
--------------------------------------------------------------------
CLASS: ShaderProgram ()
	:MODEL{
		Field 'vsh' :string();
		Field 'fsh' :string();
		Field 'uniformScript' :string();
		Field 'attributeScript' :string();
	}

--------------------------------------------------------------------
CLASS: Shader ()
	:MODEL{}

--------------------------------------------------------------------
--class shader program
--------------------------------------------------------------------
function ShaderProgram:__init()
	self.prog =  MOAIShaderProgram.new()
	self.uniformTable = {}
	self.built = false

	self.uniformScript = ''
	self.vsh = ''
	self.fsh = ''

	self.uniforms   = {}
	self.attributes = false

end

function ShaderProgram:getMoaiShaderProgram()
	return self.prog
end

function ShaderProgram:build( force )
	if self.built and not force then return end

	local prog  = self.prog
	prog:load( self.vsh, self.fsh)
	prog.source = self

	--setup variables
	local attrs = self.attributes or {'position', 'uv', 'color'}
	if attrs then
		for i, a in ipairs(attrs) do
			assert( type(a)=='string' )
			prog:setVertexAttribute(i,a)
		end
	end

	local uniforms = self.uniforms
	local uniformTable = {}
	if uniforms then
		local count = #uniforms
		prog:reserveUniforms(count)
		for i, u in ipairs(uniforms) do
			local utype  = u.type
			local uvalue = u.value
			local name   = u.name

			if     utype == 'float' then
				prog:declareUniformFloat( i, name, uvalue or 0 )

			elseif utype == 'int' then
				prog:declareUniformInt( i, name, uvalue or 0 )	

			elseif utype == 'color' then
				prog:declareUniform( i, name, MOAIShader.UNIFORM_COLOR )

			elseif utype == 'sampler' then
				prog:declareUniformSampler( i, name, uvalue or 1 )

			elseif utype == 'transform' then
				prog:declareUniform( i,name, MOAIShader.UNIFORM_TRANSFORM )

			elseif utype == 'pen_color' then
				prog:declareUniform( i,name,MOAIShader.UNIFORM_PEN_COLOR )

			elseif utype == 'view_proj' then
				prog:declareUniform( i,name,MOAIShader.UNIFORM_VIEW_PROJ )

			elseif utype == 'world_view_proj' then
				prog:declareUniform( i,name,MOAIShader.UNIFORM_WORLD_VIEW_PROJ )

			end
			uniformTable[ name ] = i
		end
	end
	self.uniformTable = uniformTable
	self.built = true
end

function ShaderProgram:requestShader()	
	if not self.built then self:build() end
	local shader = Shader()
	shader:setProgram( self )
	return shader
end

--------------------------------------------------------------------
--class shader
--------------------------------------------------------------------
-- local tmpNode      = MOAIShader.new()
-- local _setAttrLink = MOAIShader.setAttrLink
-- local _setAttr     = MOAIShader.setAttr
-- local _seekAttr    = MOAIShader.seekAttr
-- local _moveAttr    = MOAIShader.moveAttr

function Shader:__init()
	self.shader = MOAIShader.new()
end

function Shader:setProgram( prog )
	self.prog = prog
	self.shader:setProgram( prog:getMoaiShaderProgram() )
end

function Shader:getMoaiShader()
	return self.shader
end

function Shader:getAttrId( name )	
	return self.prog.uniformTable[ name ]
end

function Shader:setAttr( name, v )
	local id = self.prog.uniformTable[ name ]
	if not id then error('undefined uniform:'..name, 2) end
	self.shader:setAttr( id, v )
end

function Shader:setAttrLink( name, node, id1 )
	local id = self.prog.uniformTable[ name ]
	if not id then error('undefined uniform:'..name, 2) end
	self.shader:setAttrLink( id, node, id1 )
end

-- function Shader:seekAttr( name, v, duration, ease )
-- 	local id = self.prog.uniformTable[ name ]
-- 	if not id then error('undefined uniform:'..name, 2) end
-- 	return self.shader:seekAttr( id, v, duration, ease )
-- end

-- function Shader:moveAttr( name, v, duration, ease )
-- 	local id = self.prog.uniformTable[ name ]
-- 	if not id then error('undefined uniform:'..name, 2) end
-- 	return self.shader:moveAttr( id, v, duration, ease )
-- end

--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
local function shaderLoader( node )
	local packData   = loadAssetDataTable( node:getObjectFile('def') )
	local prog = deserialize( nil, packData )
	return prog
end

registerAssetLoader ( 'shader', shaderLoader )
