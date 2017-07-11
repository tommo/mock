module 'mock'


--------------------------------------------------------------------
CLASS: PaintCanvasTile ()
	:MODEL{}

function PaintCanvasTile:__init( canvas, x, y )
	self.parentCanvas = canvas
	self.x = x
	self.y = y

	self.w = canvas.gridWidth
	self.h = canvas.gridHeight
end



--------------------------------------------------------------------
CLASS: PaintCanvas ()
	:MODEL{}

function PaintCanvas:__init()
	self.rows = {}
	self.gridWidth  = 128
	self.gridHeight = 128
end

local floor = math.floor
function PaintCanvas:locToCoord( x, y )
	local gw, gh = self.gridWidth, self.gridHeight
	local ix = 	floor( x / gw )
	local iy = 	floor( y / gw )
	return ix, iy
end

function PaintCanvas:getTile( x, y )
	local rows = self.rows
	local row = rows[ y ]
	if not row then return nil end
end

function PaintCanvas:affirmTile( x, y )
	local gw, gh = self.gridWidth, self.gridHeight
	local rows = self.rows
	local row = rows[ y ]
	if not row then
		row = {}
		rows[ y ] = row
		local tile = PaintCanvasTile( self, x, y )
		row[ x ] = tile
		return tile
	end

	local tile = row[ x ]
	if not tile then
		tile = PaintCanvasTile( self, x, y )
		row[ x ] = tile
	end
	return tile
end

function PaintCanvas:affirmTileRect( x0, y0, x1, y1 )
	if x0 > x1 then x0, x1 = x1, x0 end
	if y0 > y1 then y0, y1 = y1, y0 end
	local rows = self.rows
	for iy = y0, y1 do
		local row = rows[ iy ]
		if not row then
			row = {}
			rows[ iy ] = row
			for ix = x0, x1 do
				row[ ix ] = PaintCanvasTile( self, x, y )
			end
		else
			for ix = x0, x1 do
				local tile = row[ ix ]
				if not tile then 
					tile = PaintCanvasTile( self, x, y )
					row[ ix ] = tile
				end
			end
		end
	end
end


--------------------------------------------------------------------
CLASS: PaintCanvasCameras ()
	:MODEL{}


--------------------------------------------------------------------
CLASS: PaintBrush ()
	:MODEL{}



