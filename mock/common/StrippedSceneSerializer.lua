module 'mock'

--TODO

--------------------------------------------------------------------
CLASS: StrippedSceneSerializer (SceneSerializer)
function StrippedSceneSerializer:postSerialize( scene, data, objMap )
end

function StrippedSceneSerializer:preSerialize( scene, data )
end

--------------------------------------------------------------------
CLASS: StrippedSceneDeserializer (SceneDeserializer)

function StrippedSceneDeserializer:preDeserialize( scene, data, objMap )
end

function StrippedSceneDeserializer:postDeserialize( scene, data, objMap )
end

--------------------------------------------------------------------
function useStrippedSceneSerializer()
	setSceneSerializer( StrippedSceneSerializer(), StrippedSceneDeserializer() )
end
