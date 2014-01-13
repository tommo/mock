module 'mock'
CLASS: ThreadImageLoadTask ( ThreadTask )
	:MODEL{}

function ThreadImageLoadTask:__init( path, transform )
	self.imagePath = path
	self.imageTransform = transform
end

function ThreadImageLoadTask:onExec( queue )
	local imgTask = MOAIImageLoadTask.new()
	imgTask:start(
		queue:getThread(),
		self.imagePath,
		self.imageTransform,
		function( img )
			if img:getSize() <= 0 then
				return self:fail()				
			else
				return self:complete( img )
			end
		end
	 )
end
