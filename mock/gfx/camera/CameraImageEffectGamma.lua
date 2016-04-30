module 'mock'

local function buildGammaShader()
	local vsh = [[
		attribute vec4 position;
		attribute vec2 uv;
		attribute vec4 color;

		varying LOWP vec4 colorVarying;
		varying MEDP vec2 uvVarying;

		void main () {
			gl_Position = position;
			uvVarying = uv;
			colorVarying = color;
		}
	]]

	local fsh = [[	
		varying LOWP vec4 colorVarying;
		varying MEDP vec2 uvVarying;
		uniform float gamma;

		uniform sampler2D sampler;

		void main () {
			LOWP vec4 color = texture2D ( sampler, uvVarying );
		  gl_FragColor.rgb = pow(color.rgb, vec3(1.0/gamma) );
		}
	]]

	local prog = buildShaderProgramFromString( vsh, fsh , {
			uniforms = {
				{
					name = "sampler",
					type = "sampler",
					value = 1
				},
				{
					name = "gamma",
					type = "float",
					value = 1.0
				}
			}
		} )
	return prog:buildShader()
end

--------------------------------------------------------------------
CLASS: CameraImageEffectGamma ( CameraImageEffect )
	:MODEL{
		Field 'gamma' :onset( 'updateParam' ) :meta{ step = 0.1 };
}

function CameraImageEffectGamma:__init()
	self.gamma = 1.8
	self.shader = false
end

function CameraImageEffectGamma:onBuild( prop, layer )
	self.shader = buildGammaShader()
	prop:setShader( self.shader:getMoaiShader() )
	self:updateParam()
end

function CameraImageEffectGamma:updateParam()
	if not self.shader then return end
	self.shader:setAttr( 'gamma', self.gamma )
end

mock.registerComponent( 'CameraImageEffectGamma', CameraImageEffectGamma )
