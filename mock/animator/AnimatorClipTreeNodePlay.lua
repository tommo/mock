module 'mock'	

--------------------------------------------------------------------
CLASS: AnimatorClipTreeNodePlay ( AnimatorClipTreeNode )
	:MODEL{
		Field 'clip' :string() :selection( 'getClipNames' );
		Field 'playMode' :enum( EnumTimerMode );
		Field 'throttle' :float() :meta{step=0.1};
	}

function AnimatorClipTreeNodePlay:__init()
	self.clip = false
	self.throttle = 1
	self.playMode = MOAITimer.LOOP
end

function AnimatorClipTreeNodePlay:getClipNames()
	local package = self:getParentTree():getParentPackage()
	return package:getClipNames()
end

function AnimatorClipTreeNodePlay:getTypeName()
	return 'play'
end

function AnimatorClipTreeNodePlay:getIcon()
	return 'animator_clip_tree_node_play'
end

function AnimatorClipTreeNodePlay:toString()
	if self.clip then
		return string.format( 'play %q', self.clip )
	else
		return 'play <nil>'
	end
end

function AnimatorClipTreeNodePlay:onStateLoad( treeState )
	local state = treeState:addSubState( self, self.clip, self.playMode )

end

function AnimatorClipTreeNodePlay:evaluate( treeState )
	treeState:updateSubState( self, 1, self.throttle )
end

function AnimatorClipTreeNodePlay:acceptChildType( typeName )
	return false
end

--------------------------------------------------------------------
registerAnimatorClipTreeNodeType( 'play',     AnimatorClipTreeNodePlay )
