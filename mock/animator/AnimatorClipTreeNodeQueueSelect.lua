module 'mock'	

-------------------------------------------------------------------
CLASS: AnimatorClipTreeNodeQueuedSelect ( AnimatorClipTreeNode )
	:MODEL{
		Field 'looped' :boolean();
	}

function AnimatorClipTreeNodeQueuedSelect:__init()
	self.looped = false
	self.childrenCount = 0
end

function AnimatorClipTreeNodeQueuedSelect:toString()
	return 'queue select'
end

function AnimatorClipTreeNodeQueuedSelect:getTypeName()
	return 'queue_select'
end

function AnimatorClipTreeNodeQueuedSelect:acceptChildType( typeName )
	return true
end

function AnimatorClipTreeNodeQueuedSelect:getIcon()
	return 'animator_clip_tree_node_group'
end

function AnimatorClipTreeNodeQueuedSelect:onStateLoad( treeState )
	self.childrenCount = #self.children
	return AnimatorClipTreeNodeQueuedSelect.__super.onStateLoad( self, treeState )
end

function AnimatorClipTreeNodeQueuedSelect:evaluate( treeState )
	local count = self.childrenCount
	if count <= 0 then return end
	
	local vars = treeState:getNodeVars( self )
	local idx = vars[ 'index' ] or 1
	if self.looped then
		vars[ 'index' ] = ( idx + 1 ) % count + 1
	elseif idx < count then
		vars[ 'index' ] = idx + 1
	end

	local child = self.children[ idx ]
	return child:evaluate( treeState )

end


registerAnimatorClipTreeNodeType( 'queue_select',   AnimatorClipTreeNodeQueuedSelect )
