module 'mock'

local function buildSharpenShader()
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

		uniform sampler2D sampler;
		uniform float viewWidth;
		uniform float viewHeight;

		void main () {
			float du = 1.0/viewWidth  * 1.0;
			float dv = 1.0/viewHeight * 1.0;
			gl_FragColor = texture2D ( sampler, uvVarying ) * 2.0;
			gl_FragColor -= texture2D ( sampler, uvVarying + vec2( 0.0,  dv ) ) * 0.15;
			gl_FragColor -= texture2D ( sampler, uvVarying + vec2( 0.0, -dv ) ) * 0.15;
			gl_FragColor -= texture2D ( sampler, uvVarying + vec2(  du, 0.0 ) ) * 0.15;
			gl_FragColor -= texture2D ( sampler, uvVarying + vec2( -du, 0.0 ) ) * 0.15;
			gl_FragColor -= texture2D ( sampler, uvVarying + vec2(  du,  dv ) ) * 0.08;
			gl_FragColor -= texture2D ( sampler, uvVarying + vec2(  du, -dv ) ) * 0.08;
			gl_FragColor -= texture2D ( sampler, uvVarying + vec2( -du,  dv ) ) * 0.08;
			gl_FragColor -= texture2D ( sampler, uvVarying + vec2( -du, -dv ) ) * 0.08;
		}
	]]

	local prog = buildShaderProgramFromString( vsh, fsh, {
		uniforms = {
			{
				name = "sampler",
				type = "sampler",
				value = 1
			},
			{
				name = "time",
				type = "float",
				value = 0
			},
			{
				name = "intensity",
				type = "float",
				value = 2
			}
		},
		globals = {
			{
				name = 'viewWidth',
				type = 'GLOBAL_VIEW_WIDTH',
			},
			{
				name = 'viewHeight',
				type = 'GLOBAL_VIEW_HEIGHT',
			}
		}
	} )
	return prog:buildShader():getMoaiShader()
end

--------------------------------------------------------------------
CLASS: CameraImageEffectSharpen ( CameraImageEffect )
	:MODEL{}

function CameraImageEffectSharpen:onBuild( prop, layer )
	prop:setShader( assert( buildSharpenShader() ) )
end


mock.registerComponent( 'CameraImageEffectSharpen', CameraImageEffectSharpen )