--------------------------------------------------------------------
---- Base
require 'mock.component.Behaviour'
require 'mock.component.UpdateListener'
require 'mock.component.IntervalUpdateListener'
require 'mock.component.RenderComponent'
require 'mock.component.DeckComponent'

--------------------------------------------------------------------
---- Prefab
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

--------------------------------------------------------------------
---- Graphics
require 'mock.component.Prop'
require 'mock.component.Text'
require 'mock.component.TextLabel'
-- require 'mock.component.TileMap'
require 'mock.component.NamedTileMap'
require 'mock.component.PatchSprite'
-- require 'mock.component.PatchProp'
require 'mock.component.ParticleSystem'
require 'mock.component.ParticleEmitter'
require 'mock.component.TiledTextureRect'

require 'mock.component.DrawScript'
require 'mock.component.InputScript'

require 'mock.component.Geometry'
require 'mock.component.TexturePlane'

--------------------------------------------------------------------
---- Actor ?
require 'mock.component.MsgEmitter'
require 'mock.component.MsgRedirector'

--------------------------------------------------------------------
---- Audio
require 'mock.component.Audio'


--------------------------------------------------------------------
---- Physics
require 'mock.component.PhysicsBody'
require 'mock.component.PhysicsShape'
require 'mock.component.PhysicsJoint'
require 'mock.component.PhysicsTrigger'
require 'mock.component.PhysicsTriggerArea'
--------------------------------------------------------------------
---- Extended
require 'mock.component.AuroraSprite'
require 'mock.component.MSprite'
require 'mock.component.SpineSpriteBase'
require 'mock.component.SpineSprite'
require 'mock.component.SpineSpriteSimple'

--------------------------------------------------------------------
---- AI
require 'mock.component.FSMController'
require 'mock.component.BTController'
require 'mock.component.SteerController'

--------------------------------------------------------------------
require 'mock.component.EffectEmitter'

--------------------------------------------------------------------
require 'mock.component.Layout'
--------------------------------------------------------------------
--EFFECTS
require 'mock.component.CameraImageEffectGrayScale'
require 'mock.component.CameraImageEffectInvert'
require 'mock.component.CameraImageEffectColorGrading'
