module 'mock'

--------------------------------------------------------------------
CLASS: FontEntry()
	:MODEL{
		Field 'id'   :string();
		Field 'font' :asset( 'font|font_bmfont' );
}

function FontEntry:__init()
	self.id = 'font'
	self.font = false
end

--------------------------------------------------------------------
CLASS: TBSkin ()
	:MODEL{
		Field 'superSkin' :asset( 'tb_skin' );
		Field 'config'    :string();
		Field 'fonts'     :array( FontEntry ) :sub();
	}

function TBSkin:__init()
	-- self._moaiSkin = 
	self.superSkin = false
	self.name      = "skin"
	self.config    = ""
	self.fonts     = {}
	self.dataPath  = false
	self.skin = MOAITBSkin.new()
end

function TBSkin:affirm()
end

function TBSkin:_load( path )
	self.dataPath = path
	local defineName = 'skin.tb.txt'
	-- self.skin:load( defineName )
end

--------------------------------------------------------------------
function TBSkinLoader( node )
	local skin = TBSkin()
	skin:_load( node:getObjectFile( 'export' ) )
	return skin
end

registerAssetLoader( 'tb_skin', TBSkinLoader )
