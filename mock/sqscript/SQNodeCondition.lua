module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeBranch ( SQNodeGroup )
	:MODEL{}

function SQNodeBranch:__init()
	self.name = 'branch'
end

function SQNodeBranch:exit( context, env )
	context:setJumpTarget( self.parentNode:getNextSibling() )
	return 'jump'
end

function SQNodeBranch:getRichText()
	return string.format( '<branch>%s</branch>', self.name )
end

function SQNodeBranch:getIcon()
	return 'sq_node_branch'
end

function SQNodeBranch:isBuiltin()
	return true
end

--------------------------------------------------------------------
CLASS: SQNodeBranchYes ( SQNodeBranch )
	:MODEL{}

function SQNodeBranchYes:getRichText()
	return string.format( '<branch>Yes</branch>' )
end

function SQNodeBranchYes:getIcon()
	return 'sq_node_branch_yes'
end

--------------------------------------------------------------------
CLASS: SQNodeBranchNope ( SQNodeBranch )
	:MODEL{}

function SQNodeBranchNope:getRichText()
	return string.format( '<branch>No</branch>' )
end

function SQNodeBranchNope:getIcon()
	return 'sq_node_branch_no'
end

--------------------------------------------------------------------
CLASS: SQNodeCondition ( SQNodeGroup )
	:MODEL{}

function SQNodeCondition:__init()
	self.branchTrue = false
	self.branchFalse = false
end

function SQNodeCondition:getBranchTrue()
	return self.branchTrue
end

function SQNodeCondition:getBranchFalse()
	return self.branchFalse
end

function SQNodeCondition:affirmBranches()
	if self.branchTrue then return end
	self.branchTrue = SQNodeBranchYes()
	self.branchFalse = SQNodeBranchNope()
	self.branchTrue.name = 'Yes'
	self.branchTrue.name = 'No'
	self:addChild( self.branchTrue )
	self:addChild( self.branchFalse )
end

function SQNodeCondition:initFromEditor()
	self:affirmBranches()
end

function SQNodeCondition:checkCondition( context, env )
	return true
end

function SQNodeCondition:enter( context, env )
	local checked = self:checkCondition( context, env )
	local target = checked and self.branchTrue or self.branchFalse
	context:setJumpTarget( target )
	return 'jump'
end

function SQNodeCondition:canInsert()
	return false
end

function SQNodeCondition:getIcon()
	return 'sq_node_condition'
end

function SQNodeCondition:build()
	for i, child in ipairs( self.children ) do
		if child:isInstance( SQNodeBranchYes ) then
			self.branchTrue = child
		elseif child:isInstance( SQNodeBranchNope ) then
			self.branchFalse = child
		end
	end
end


--------------------------------------------------------------------
CLASS: SQNodeIfExpr ( SQNodeCondition )
	:MODEL{
		Field 'expr' :string();
	}

function SQNodeIfExpr:__init()
	self.expr = 'true'
end

function SQNodeIfExpr:checkCondition( context, env )
	return true
end

function SQNodeIfExpr:getRichText()
	return string.format( '<condition>%s</condition>?', self.expr )
end


-- --------------------------------------------------------------------
-- CLASS: SQNodeIfVar ( SQNodeCondition )
-- 	:MODEL{
-- 		Field 'varId' :string();
-- 	}

-- function SQNodeIfVar:checkCondition( context, env )
-- 	return true
-- end

-- function SQNodeIfVar:getRichText()
-- 	return string.format( '<condition>%s</condition>?', self.expr )
-- end

--------------------------------------------------------------------
registerSQNode( 'if_expr', SQNodeIfExpr )
-- registerSQNode( 'if_var', SQNodeIf )
