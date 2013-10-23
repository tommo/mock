module 'mock'
-- CLASS: ShaderEffectManager ()
-- 	:MODEL{}

--------------------------------------------------------------------
CLASS: Shader ()
	:MODEL{
		Field 'vsh' :string();
		Field 'fsh' :string();
	}
--------------------------------------------------------------------
function Shader:__init()
	self.shader =  MOAIShader.new()
	self.shader.uniformTable = {}
end

function Shader:getMoaiShader()
	return self.shader
end

local _setAttr     = MOAIShader.setAttr
local _setAttrLink = MOAIShader.setAttrLink

function Shader:setAttr( name, v )
	local shader = self.shader
	local tt = type( name )
	if tt == 'number' then return _setAttr( shader, name, v )  end
	local ut = shader.uniformTable
	local id = ut[ name ]
	if not id then error('undefined uniform:'..name, 2) end
	_setAttr( shader, id, v )
end

function Shader:setAttrLink( name, v )
	local shader = self.shader
	local tt = type( name )
	if tt == 'number' then return _setAttrLink( shader, name, v )  end
	local ut = shader.uniformTable
	local id = ut[ name ]
	if not id then error('undefined uniform:'..name, 2) end
	_setAttrLink( shader, id, v )
end

function Shader:update()
	local vsh,fsh=option.vsh,option.fsh

	local shader= self.shader
	shader:load(vsh,fsh)
	shader.source = self

	--setup variables
	local attrs = option.attributes or {'position', 'uv', 'color'}
	if attrs then
		for i, a in ipairs(attrs) do
			assert(type(a)=='string')
			shader:setVertexAttribute(i,a)
		end
	end

	local uniforms=option.uniforms
	local uniformTable = {}
	if uniforms then
		local count=#uniforms
		shader:reserveUniforms(count)
		for i, u in ipairs(uniforms) do
			local utype=u.type
			local uvalue=u.value
			local name=u.name

			if utype=='float' then
				shader:declareUniformFloat(i, name, uvalue or 0)
			elseif utype=='int' then
				shader:declareUniformInt(i, name, uvalue or 0)			
			elseif utype=='color' then
				shader:declareUniform(i,name,MOAIShader.UNIFORM_COLOR)
			elseif utype=='sampler' then
				shader:declareUniformSampler(i, name, uvalue or 1)
			elseif utype=='transform' then
				shader:declareUniform(i,name, MOAIShader.UNIFORM_TRANSFORM)
			elseif utype=='pen_color' then
				shader:declareUniform(i,name,MOAIShader.UNIFORM_PEN_COLOR)
			elseif utype=='view_proj' then
				shader:declareUniform(i,name,MOAIShader.UNIFORM_VIEW_PROJ)
			elseif utype=='world_view_proj' then
				shader:declareUniform(i,name,MOAIShader.UNIFORM_WORLD_VIEW_PROJ)
			end
			uniformTable[ name ] = i

		end
	end
	shader.uniformTable = uniformTable

end

--------------------------------------------------------------------
local function shaderLoader( node )
	local packData   = loadAssetDataTable( node:getObjectFile('def') )
	local shader = deserialize( nil, packData )
	return shader
end

registerAssetLoader ( 'shader', shaderLoader )
