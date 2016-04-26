module 'mock'	

--------------------------------------------------------------------
CLASS: AnimatorClipTreeNodeThrottle ( AnimatorClipTreeNode )
	:MODEL{
		Field 'throttle' :float() :meta{ step=0.1 };
	}

function AnimatorClipTreeNodeThrottle:__init()
	self.throttle = 1
end

function AnimatorClipTreeNodeThrottle:getTypeName()
	return 'throttle'
end

function AnimatorClipTreeNodeThrottle:getIcon()
	return 'animator_clip_tree_node_throttle'
end

function AnimatorClipTreeNodeThrottle:toString()
	return string.format( 'throttle x %.2f', self.throttle )
end

function AnimatorClipTreeNodeThrottle:evaluate( treeState )
	local throttle0 = treeState.throttle
	treeState.throttle = throttle0 * self.throttle
	self:evaluateChildren( treeState )
	treeState.throttle = throttle0
end

function AnimatorClipTreeNodeThrottle:acceptChildType( typename )
	return true
end

--------------------------------------------------------------------
registerAnimatorClipTreeNodeType( 'throttle',     AnimatorClipTreeNodeThrottle )
