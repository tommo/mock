module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeCondition ( SQNode )
	:MODEL{}

function SQNodeCondition:__init()
	self.branchTrue = SQNodeGroup()
	self.branchFalse = SQNodeGroup()
	self:addChild( self.branchTrue )
	self:addChild( self.branchFalse )
	-- self.branchTrue:setBundled()
	-- self.branchFalse:setBundled
end

function SQNodeCondition:checkCondition( context, env )
	return true
end

function SQNodeCondition:enter( context, env )
end


--------------------------------------------------------------------
CLASS: SQNodeIfExpr ( SQNodeCondition )
	:MODEL{
		Field 'expr' :string();
	}

function SQNodeIfExpr:checkCondition( context, env )
	return true
end



--------------------------------------------------------------------
CLASS: SQNodeIfVar ( SQNodeCondition )
	:MODEL{
		Field 'id' :string();
	}

function SQNodeIfVar:checkCondition( context, env )
	return true
end

--------------------------------------------------------------------
registerSQNode( 'if_expr', SQNodeIfExpr )
registerSQNode( 'if_var', SQNodeIf )
