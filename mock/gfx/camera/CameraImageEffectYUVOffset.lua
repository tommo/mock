module 'mock'

local function buildShader()
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
		uniform float intensity;

		void main () {
			float du = 1.0/viewWidth  * 1.05;
			float dv = 1.0/viewHeight * 1.05;
			vec4 c = texture2D ( sampler, uvVarying );
			vec4 cc = c* 0.54;
			cc += texture2D ( sampler, uvVarying + vec2( 0.0,  dv ) ) * 0.05 * vec4( 1.0, 0.0, 1.0, 1.0);
			cc += texture2D ( sampler, uvVarying + vec2( 0.0, -dv ) ) * 0.05 * vec4( 0.0, 1.0, 0.0, 1.0);
			cc += texture2D ( sampler, uvVarying + vec2(  du, 0.0 ) ) * 0.3 * vec4( 1.0, 0.0, 1.0, 1.0);
			cc += texture2D ( sampler, uvVarying + vec2( -du, 0.0 ) ) * 0.3 * vec4( 0.0, 1.0, 0.0, 1.0);
			cc += texture2D ( sampler, uvVarying + vec2(  du,  dv ) ) * 0.05 * vec4( 1.0, 0.0, 1.0, 1.0);
			cc += texture2D ( sampler, uvVarying + vec2(  du, -dv ) ) * 0.05 * vec4( 1.0, 0.0, 1.0, 1.0);
			cc += texture2D ( sampler, uvVarying + vec2( -du,  dv ) ) * 0.05 * vec4( 0.0, 1.0, 0.0, 1.0);
			cc += texture2D ( sampler, uvVarying + vec2( -du, -dv ) ) * 0.05 * vec4( 0.0, 1.0, 0.0, 1.0);
			gl_FragColor = mix( c, cc, intensity );
		}
	]]

	local prog = buildShaderProgramFromString( vsh, fsh, {
		uniforms = {
			{
				name = "intensity",
				type = "float",
				value = 1
			},
			{
				name = "sampler",
				type = "sampler",
				value = 1
			},
			{
				name = "time",
				type = "float",
				value = 0
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
	return prog:buildShader()
end

--------------------------------------------------------------------
CLASS: CameraImageEffectYUVOffset ( CameraImageEffect )
	:MODEL{}

function CameraImageEffectYUVOffset:onBuild( prop, layer )
	self.shader = assert( buildShader() )
	prop:setShader( self.shader:getMoaiShader() )
	self.shader:setAttr( 'intensity', self.intensity or 1 )
end

function CameraImageEffectYUVOffset:setIntensity( intensity )
	self.intensity = intensity
	if self.shader then
		self.shader:setAttr( 'intensity', self.intensity or 1 )
	end
end


mock.registerComponent( 'CameraImageEffectYUVOffset', CameraImageEffectYUVOffset )