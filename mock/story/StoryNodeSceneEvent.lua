module 'mock'


--start / terminate a node when open/exit a scene
CLASS: StoryNodeSceneEvent ( StoryNode )
 	:MODEL{}

function StoryNodeSceneEvent:__init()
	self.sceneId = false
end

function StoryNodeSceneEvent:onLoad( nodeData )
	local sceneId = self.text
	self.sceneId = sceneId
end

registerStoryNodeType( 'SCN', StoryNodeSceneEvent )

