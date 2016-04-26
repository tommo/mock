module 'mock'

CLASS: AnimTreeNodeBlendEntry ()
	:MODEL{}

function AnimTreeNodeBlendEntry:__init()

end

--------------------------------------------------------------------
CLASS: AnimTreeNodeBlend ( AnimTreeNode )
	:MODEL{}

function AnimTreeNodeBlend:__init()
end

function AnimTreeNodeBlend:getTypeName()
	return 'blend'
end

