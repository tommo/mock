module 'mock'

--------------------------------------------------------------------
function BTSchemeLoader( node )
	local path = node:getObjectFile('def')
	local data = dofile( path )
	local tree = BehaviorTree()
	tree:load( data )
	return tree
end

--------------------------------------------------------------------
registerAssetLoader ( 'bt_scheme', BTSchemeLoader )