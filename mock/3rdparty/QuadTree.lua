-- The MIT License (MIT)

-- Copyright (c) 2015 Oliver

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.



local QuadTree = {}
QuadTree.__index = QuadTree

-- Creates the quadtree
-- If no max objects or max depth is defined, the default of 10 and 5 are used repectively
function QuadTree.create(_left, _top, _width, _height, _depth, _maxObjects, _maxDepth)
    local quadtree = {}
    setmetatable(quadtree, QuadTree)

    quadtree.objects = {}

    quadtree.nodes = {}

    quadtree.position = {}
    quadtree.position.left = _left or 0
    quadtree.position.top = _top or 0

    quadtree.dimensions = {}
    quadtree.dimensions.width = _width or 0
    quadtree.dimensions.height = _height or 0

    quadtree.depth = _depth or 0

    quadtree.maxObjects = _maxObjects or 10
    quadtree.maxDepth = _maxDepth or 5

    return quadtree
end

-- Retrieves an index for the shape, based on which child node the object fits inside
-- If the object does not intersect any child nodes, then returns -1 else
-- If the object does not fit perfectly inside a single child node, then returns 0
-- Else returns the index of the child node.
function QuadTree:index(_object)
    local index = 0

    -- Check that the object at least intersects the parent node
    if (_object.left + _object.width) < self.position.left or (self.position.left + self.dimensions.width) < _object.left or (_object.top + _object.height) < self.position.top or (self.position.top + self.dimensions.height) < _object.top then
        return -1 -- No intersection present
    end

    -- Determine which, if any, child nodes the object lies within perfectly
    local top    = _object.top < self.position.top + (self.dimensions.height / 2) and _object.top + _object.height < self.position.top + (self.dimensions.height / 2)
    local bottom = _object.top > self.position.top + (self.dimensions.height / 2)
    local left   = _object.left < self.position.left + (self.dimensions.width / 2) and _object.left + _object.width < self.position.left + (self.dimensions.width / 2)
    local right  = _object.left > self.position.left + (self.dimensions.width / 2)

    if top    and left  then index = 1 end
    if top    and right then index = 2 end
    if bottom and left  then index = 3 end
    if bottom and right then index = 4 end

    return index
end

-- Create child nodes
function QuadTree:divide()
    local left = self.position.left
    local top = self.position.top
    local width = self.dimensions.width
    local height = self.dimensions.height

    self.nodes[1] = QuadTree.create(left              , top               , width / 2, height / 2, self.depth + 1, self.maxObjects, self.maxDepth)
    self.nodes[2] = QuadTree.create(left + (width / 2), top               , width / 2, height / 2, self.depth + 1, self.maxObjects, self.maxDepth)
    self.nodes[3] = QuadTree.create(left              , top + (height / 2), width / 2, height / 2, self.depth + 1, self.maxObjects, self.maxDepth)
    self.nodes[4] = QuadTree.create(left + (width / 2), top + (height / 2), width / 2, height / 2, self.depth + 1, self.maxObjects, self.maxDepth)
end

-- Inserts an object into the quadtree.
function QuadTree:insert(_object)
    -- Check if the quadtree has already divided
    if #self.nodes > 0 then
        -- Determine in which node the object belongs
        local index = self:index(_object)

        -- If it belongs in a child node, insert it there and return
        if index > 0 then
            self.nodes[index]:insert(_object)
            return
        end
    end

    -- Insert the object into the node's object list
    table.insert(self.objects, _object)

    -- Check if the number of objects or the depth exceeds the allowable maximum, and that the quadtree has not yet divided
    if #self.objects > self.maxObjects and self.depth < self.maxDepth and #self.nodes == 0 then
        -- Divide the quadtree
        self:divide()

        -- For each object in this node's object list, attempt to insert it into a child node
        for key, object in pairs(self.objects) do
            -- Fetch index of object
            local index = self:index(object)

            -- Insert the object into a child node if possible
            if index > 0 then
                self.nodes[index]:insert(object)

                self.objects[key] = nil
            end
        end
    end
end

-- Clears quadtree and all child nodes
function QuadTree:clear()
    self.objects = {}

    for key, _ in pairs(self.nodes) do
        self.nodes[key]:clear()
    end
end

-- Retrieve list of potential collisions
function QuadTree:collidables(_object)
    local index = self:index(_object)

    local objects = {}

    -- Check that object intersects with this node
    if index == -1 then
        return objects -- If no intersection, return no collisions
    end

    -- Add each object in this nodes objects
    for _, object in pairs(self.objects) do
        table.insert(objects, object)
    end

    -- If this node has children
    if #self.nodes ~= 0 then
        -- If the object perfectly fits inside a child node
        if index > 0 then
            -- Retrieve potential collisions in that child node
            for _, object in pairs(self.nodes[index]:collidables(_object)) do
                table.insert(objects, object)
            end
        -- Else, retrieve collisions for all child nodes
        else
            for key, _ in pairs(self.nodes) do
                for _, object in pairs(self.nodes[key]:collidables(_object)) do
                    table.insert(objects, object)
                end
            end
        end
    end

    return objects
end

_G.QuadTree = QuadTree
