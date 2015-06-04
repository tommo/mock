module 'mock'

local function buildSepiaShader()
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
		uniform float intensity;

		uniform sampler2D sampler;

		float Luminance( in vec4 color )
		{
		    return (color.r + color.g + color.b ) / 3.0;
		}

		vec4 Sepia( in vec4 color )
		{
		    return vec4(
		          clamp(color.r * 0.393 + color.g * 0.769 + color.b * 0.189, 0.0, 1.0)
		        , clamp(color.r * 0.349 + color.g * 0.686 + color.b * 0.168, 0.0, 1.0)
		        , clamp(color.r * 0.272 + color.g * 0.534 + color.b * 0.131, 0.0, 1.0)
		        , color.a
		    );
		}

		void main () {
			LOWP vec4 color = texture2D ( sampler, uvVarying );
		  gl_FragColor = mix(color, Sepia(color), intensity );
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
					name = "intensity",
					type = "float",
					value = 1.0
				}
			}
		} )
	return prog:buildShader()
end

--------------------------------------------------------------------
CLASS: CameraImageEffectSepia ( CameraImageEffect )
	:MODEL{
		Field 'intensity' :onset( 'updateIntensity' ) :meta{ step = 0.1 };
}

function CameraImageEffectSepia:__init()
	self.intensity = 1
	self.shader = false
end

function CameraImageEffectSepia:onBuild( prop, layer )
	self.shader = buildSepiaShader()
	prop:setShader( self.shader:getMoaiShader() )
	self:updateIntensity()
end

function CameraImageEffectSepia:updateIntensity()
	if not self.shader then return end
	self.shader:setAttr( 'intensity', self.intensity )
end

mock.registerComponent( 'CameraImageEffectSepia', CameraImageEffectSepia )
