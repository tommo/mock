module 'mock'

registerSignals{
	'ui.button.press',
	'ui.button.release',
	'ui.button.click',
}

CLASS: GUIButtonBase ( GUIWidget )
	:MODEL{}

function GUIButtonBase:onLoad()
end
