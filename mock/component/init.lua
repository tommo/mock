--------------------------------------------------------------------
---- Base
require 'mock.component.Behaviour'
require 'mock.component.UpdateListener'
require 'mock.component.IntervalUpdateListener'
require 'mock.component.RenderComponent'
require 'mock.component.GraphicsPropComponent'
require 'mock.component.DeckComponent'
require 'mock.component.DeckComponentArray'

--------------------------------------------------------------------
---- Prefab
require 'mock.component.ProtoSpawner'
require 'mock.component.ProtoArraySpawner'
require 'mock.component.PrefabSpawner'

--------------------------------------------------------------------
---- Input
require 'mock.component.InputListener'

--------------------------------------------------------------------
---- Basic components
require 'mock.component.CameraManager'
require 'mock.component.CameraPass'
require 'mock.component.Camera'
require 'mock.component.CameraImageEffect'
require 'mock.component.StereoCamera'
require 'mock.component.ScreenAnchor'

require 'mock.component.TransformLink'

--------------------------------------------------------------------
---- Graphics
require 'mock.component.Prop'
-- require 'mock.component.Text'
require 'mock.component.TextLabel'
require 'mock.component.PatchSprite'

require 'mock.component.DrawScript'
require 'mock.component.InputScript'

require 'mock.component.Geometry'
require 'mock.component.TexturePlane'
require 'mock.component.TiledTextureRect'
require 'mock.component.TextureCircle'

require 'mock.component.TileMap'
require 'mock.component.NamedTileMap'
require 'mock.component.TileMap2D'
require 'mock.component.CodeTileMapLayer'

require 'mock.component.ParticleSystem'
require 'mock.component.ParticleEmitter'

--------------------------------------------------------------------
---- Actor ?
require 'mock.component.MsgEmitter'
require 'mock.component.MsgRedirector'

--------------------------------------------------------------------
---- Audio
require 'mock.component.SoundSource'
require 'mock.component.SoundListener'
require 'mock.component.SoundSourceAnimatorTrack'


--------------------------------------------------------------------
---- Physics
require 'mock.component.PhysicsBody'
require 'mock.component.PhysicsShape'
require 'mock.component.PhysicsJoint'
require 'mock.component.PhysicsTrigger'
require 'mock.component.PhysicsTriggerArea'

require 'mock.component.PhysicsShapeCommon'
require 'mock.component.PhysicsShapeBevelBox'
require 'mock.component.PhysicsShapePie'

--------------------------------------------------------------------
---- Extended
require 'mock.component.AuroraSprite'

require 'mock.component.MSprite'
require 'mock.component.MSpriteCopy'
require 'mock.component.MSpriteAnimatorTrack'

require 'mock.component.SpineSpriteBase'
require 'mock.component.SpineSprite'
require 'mock.component.SpineSpriteSimple'

--------------------------------------------------------------------
---- AI
require 'mock.component.FSMController'

--------------------------------------------------------------------
require 'mock.component.Path'


--------------------------------------------------------------------
require 'mock.component.EffectEmitter'

--------------------------------------------------------------------
require 'mock.component.Layout'

--------------------------------------------------------------------
--EFFECTS
require 'mock.component.CameraImageEffectGrayScale'
require 'mock.component.CameraImageEffectSepia'
require 'mock.component.CameraImageEffectInvert'
require 'mock.component.CameraImageEffectColorGrading'
require 'mock.component.CameraImageEffectBlur'
require 'mock.component.CameraImageEffectSharpen'
require 'mock.component.CameraImageEffectBloom'
require 'mock.component.CameraImageEffectRadialBlur'
require 'mock.component.CameraImageEffectMosaic'
require 'mock.component.CameraImageEffectYUVOffset'


--------------------------------------------------------------------
--ETC
require 'mock.component.BehaviourScript'
require 'mock.component.ShakeController'

