module 'mock'

CLASS: GridStruct ()
	:MODEL{}
function GridStruct:init(col,row)
	self.data = {}
	self.col,self.row = col, row
end

function GridStruct:fill(d)
	local data=self.data
	for i = 0, self.col*self.row-1 do
		data[i]=d
	end
end

function GridStruct:inside(x,y)
	x = x - 1
	y = y - 1
	return not( x<0 or y<0 or x>=self.col or y>=self.row)
end

function GridStruct:get(x,y)
	local i = (y-1)*self.col + (x-1)
	return self.data[i]
end

function GridStruct:set(x,y,e)
	assert( self:inside(x,y), 'grid bound exceeded' )
	local i=(y-1)*self.col+(x-1)
	self.data[i]=e
	return e
end

function GridStruct:pairs()
	return pairs(self.data)
end

function GridStruct:indexToPos(i)
	local y=math.floor(i/self.col)
	local x=i-y*self.col
	return x+1, y+1
end

function GridStruct:clone()
	local ng=GridStruct()
	ng.col,ng.row=self.col,self.row
	ng.data=table.simplecopy(self.data)
	return ng
end

function GridStruct:rotate(ccw)
	local col,row=self.col,self.row
	assert(col==row)

	local newg=GridStruct()
	newg:init(self.col,self.row)

	if ccw then
		for i=1,self.col do
			for j=1,self.row do
				newg:set( j, i, self:get(i,j) )
			end
		end
	else
		for i=1,self.col do
			for j=1,self.row do
				newg:set( col-i, row-j, self:get(i,j) )
			end
		end
	end
	return newg
end

function GridStruct:flipH()
	local newg = GridStruct()
	newg:init( self.col, self.row )
	local col=self.col
	for i = 1, self.col do
		for j = 1, self.row do
			newg:set( col-i, j, self:get( i, j ) )
		end
	end
	return newg
end

function GridStruct:flipV()
	local newg=GridStruct()
	newg:init(self.col,self.row)
	local col,row=self.col,self.row
	for i = 1,col do
		for j = 1,row do
			newg:set( i, row-j, self:get( i, j ) )
		end
	end
	return newg
end

function GridStruct:shift(x,y)
	local newg=GridStruct()
	newg:init(self.col,self.row)
	local col,row=self.col,self.row
	for i = 1,col do
		for j = 1,row do
			local x1,y1 = i-x, j-y
			if not ( x1<1 or y1<1 or x1>col or y1>row ) then 
				newg:set( i,j, self:get(x1,y1) )
			end
		end
	end
	return newg
end


function GridStruct:shiftRow( row, deltaX )
	local newg = self:clone()
	local col = self.col

	while deltaX >= col do
		deltaX = deltaX - col
	end
	while deltaX < 0 do
		deltaX = deltaX + col
	end

	for x = 1, col do
		local wrapped = ( x + deltaX ) 
		if wrapped > col then wrapped = wrapped - col end
		newg:set( x, row, self:get( wrapped, row ) )
	end
	return newg

end


function GridStruct:shiftColumn( col, deltaY )
	local newg = self:clone()
	local row = self.row

	while deltaY >= row do
		deltaY = deltaY - row
	end
	while deltaY < 0 do
		deltaY = deltaY + row
	end

	for y = 1, row do
		local wrapped = ( y + deltaY ) 
		if wrapped > row then wrapped = wrapped - row end
		newg:set( col, y, self:get( col, wrapped ) )
	end
	return newg
	
end

