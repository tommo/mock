module 'mock'

--------------------------------------------------------------------
CLASS: CommentItem ()
	:MODEL{
		Field '__guid' :string();
}

function CommentItem:__init()
	self.__guid = MOAIEnvironment.generateGUID()
end

function CommentItem:getId()
	return self.__guid
end

function CommentItem:createVisualizer()
end


--------------------------------------------------------------------
CLASS: CommentItemVisualizer ( EditorEntity )
	:MODEL{}


--------------------------------------------------------------------
CLASS: CommentItemManager ( SceneManager )
	:MODEL{}


function CommentItemManager:__init()
	self.items = {}
end

function CommentItemManager:addItem( item )
	self.items[ item:getId() ] = item
end



--------------------------------------------------------------------
CLASS: CommentItemManagerFactory ( SceneManagerFactory )

function CommentItemManagerFactory:create( scn )
	local manager = CommentItemManager()
	return manager
end

function CommentItemManagerFactory:accept( scn )
	if scn.FLAG_PREVIEW_SCENE then return true end
	if scn.FLAG_EDITOR_SCENE then return false end
	if not scn:isMainScene() then return false end
	return true
end

registerSceneManagerFactory( 'CommentItemManager', CommentItemManagerFactory() )

