CLASS: ShaderEffectManager ()
	:MODEL{}

--------------------------------------------------------------------

CLASS: Shader ()
	:MODEL{
		Field 'vsh' :string();
		Field 'fsh' :string();
		Field 'attributes' :
	}


local function loadShader(option)
	local vsh,fsh=option.vsh,option.fsh

	local shader=MOAIShader.new()
	shader:load(vsh,fsh)
	if option.name then shader.name=option.name end

	--setup variables

	if option.onLoad then option.onLoad(shader)	end
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

	local _setAttr = shader.setAttr
	function shader:setAttr( name, v )
		local tt = type( name )
		if tt == 'number' then return _setAttr( self, name, v )  end
		local ut = self.uniformTable
		local id = ut[ name ]
		if not id then error('undefined uniform:'..name, 2) end
		_setAttr( self, id, v )
	end

	local _setAttrLink = shader.setAttrLink
	function shader:setAttrLink( name, v )
		local tt = type( name )
		if tt == 'number' then return _setAttrLink( self, name, v )  end
		local ut = self.uniformTable
		local id = ut[ name ]
		if not id then error('undefined uniform:'..name, 2) end
		_setAttrLink( self, id, v )
	end

	return shader
end


--------------------------------------------------------------------
	--ALPHA_TEST
	--------------------------------------------------------------------
	alpha_test={
		type='shader',
		attributes={'position','uv','color'},
		vsh=[[
			attribute vec4 position;
			attribute vec2 uv;
			attribute vec4 color;

			varying MEDP vec2 uvVarying;
			varying LOWP vec4 colorVarying;

			void main () {
				gl_Position = position;
				uvVarying = uv;
				colorVarying = color;
			}
		]],

		fsh=[[
			varying LOWP vec4 colorVarying;
			varying MEDP vec2 uvVarying;
			uniform sampler2D sampler;

			void main () {
				LOWP vec4 tex = texture2D ( sampler, uvVarying );
				if( tex.a < 0.1 ) { discard; return; }
				gl_FragColor = tex * colorVarying;
			}
		]]
	};