module 'mock'

--TODO

CLASS: DeckComponentLine ( GraphicsPropComponent )
	:MODEL{
		Field 'looped' :boolean() :isset( 'Looped' );
		'----';
		Field 'alignToLine' :booelan();
		Field 'pitch';
		Field 'pitchVariation';
}

function DeckComponentLine:__init()
	self.verts = {}
	self.looped = false
end


function DeckComponentLine:setLooped( l )
	self.looped = l
	self:update()
end

function DeckComponentLine:isLooped()
	return self.looped
end


function DeckComponentLine:update()
	--TODO
end

