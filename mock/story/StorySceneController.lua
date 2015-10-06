module 'mock'

CLASS: StorySceneController ( Behaviour )
	:MODEL{
		Field 'sceneId'    :string();
	}

registerComponent( 'StorySceneController', StorySceneController )
registerEntityWithComponent( 'StorySceneController', StorySceneController )

function StorySceneController:__init()
	self.sceneId = false
	self.context = false
end

-- function StorySceneController:onAttach( ent )
-- 	self:checkUniqueness( ent, true )
-- end

-- function StorySceneController:checkUniqueness( ent, overwrite )
-- 	--unique checking
-- 	local scene = ent.scene
-- 	if not scene then return false end
-- 	if scene.__storySceneController == self then return true end
-- 	if scene.__storySceneController then
-- 		_warn( 'multiple StorySceneController detected, config might be incorrect.')
-- 		if not overwrite then return false end
-- 	end
-- 	scene.__storySceneController = self
-- 	return true
-- end

-- -- function StorySceneController:onStart( ent )
-- -- 	if self:checkUniqueness( ent ) then
-- -- 		--send scene event
-- -- 		getStoryManager():sendSceneEvent( self.sceneId, 'enter' )
-- -- 	end
-- -- end


-- function StorySceneController:onDetach( ent )
-- 	local scene = ent.scene
-- 	if not scene then return end
-- 	if scene.__storySceneController == self then
-- 		getStoryManager():sendSceneEvent( self.sceneId, 'exit' )
-- 		scene.__storySceneController = false
-- 	end
-- end


