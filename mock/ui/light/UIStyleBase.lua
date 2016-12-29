module 'mock'

local _BaseStyleSheetSrc = [[
	style 'UIWidget' {
		color            = 'white';
		background_color = 'black';
		font             = 'default';
		font_size        = 12;
		text_align       = 'left';
		text_align_v     = 'top';
		border_width     = 2;
		border_style     = 'solid';
		border_color     = '#ccc';
	}
]] 

local _BaseStyleSheet 
function getBaseStyleSheet()
	if not _BaseStyleSheet then
		_BaseStyleSheet = UIStyleSheet()
		_BaseStyleSheet:load( _BaseStyleSheetSrc )
	end
	return _BaseStyleSheet
end


