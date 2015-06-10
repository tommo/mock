module 'mock'

CLASS: GridStruct ()
	:MODEL{}
function GridStruct:init(col,row)
	self.data={}
	self.col,self.row=col,row
end

function GridStruct:fill(d)
	local data=self.data
	for i=0, self.col*self.row-1 do
		data[i]=d
	end
end

function GridStruct:inside(x,y)
	return not( x<0 or y<0 or x>=self.col or y>=self.row)
end

function GridStruct:get(x,y)
	local i=y*self.col+x
	return self.data[i]
end

function GridStruct:set(x,y,e)
	assert(self:inside(x,y))
	local i=y*self.col+x
	self.data[i]=e
	return e
end

function GridStruct:pairs()
	return pairs(self.data)
end

function GridStruct:indexToPos(i)
	local y=math.floor(i/self.col)
	local x=i-y*self.col
	return x,y
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
		for i=0,self.col-1 do
			for j=0,self.row-1 do
				newg:set(j,i,self:get(i,j))
			end
		end
	else
		for i=0,self.col-1 do
			for j=0,self.row-1 do
				newg:set(col-1-i,row-1-j,self:get(i,j))
			end
		end
	end
	return newg
end

function GridStruct:flipH()
	local newg=GridStruct()
	newg:init(self.col,self.row)
	local col=self.col
	for i=0,self.col-1 do
		for j=0,self.row-1 do
			newg:set(col-1-i,j,self:get(i,j))
		end
	end
	return newg
end

function GridStruct:flipV()
	local newg=GridStruct()
	newg:init(self.col,self.row)
	local col,row=self.col,self.row
	for i=0,self.col-1 do
		for j=0,self.row-1 do
			newg:set(i,row-j-1,self:get(i,j))
		end
	end
	return newg
end

function GridStruct:shift(x,y)
	local newg=GridStruct()
	newg:init(self.col,self.row)
	local col,row=self.col,self.row
	for i=0,self.col-1 do
		for j=0,self.row-1 do
			local x1,y1=i-x,j-y
			if not (x1<0 or y1<0 or x1>col-1 or y1>row-1) then 
				newg:set(i,j, self:get(x1,y1))
			end
		end
	end
	return newg
end


function GridStruct:shiftRow( row, deltaX )
	local newg = self:clone()
	local col = self.col
	for x = 0,self.col-1 do
		local wrapped = x - deltaX
		if wrapped >= col then
			while wrapped > 0 do
				wrapped = wrapped - col
			end
		elseif wrapped < 0 then
			while wrapped < 0 do
				wrapped = wrapped + col
			end
		end
		newg:set( x, row, self:get( wrapped, row ) )
	end
	return newg
end

function GridStruct:shiftColumn( col, deltaY )
	local newg = self:clone()
	local row = self.row
	for y = 0, self.row-1 do
		local wrapped = y - deltaY
		if wrapped >= row then
			while wrapped > 0 do
				wrapped = wrapped - row
			end
		elseif wrapped < 0 then
			while wrapped < 0 do
				wrapped = wrapped + row
			end
		end
		newg:set( col, y, self:get( col, wrapped ) )
	end
	return newg
end
