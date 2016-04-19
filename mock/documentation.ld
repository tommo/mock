project = 'Mock'
title = 'Mock API Documentation'
-- new_type("member","Member", false, "field")
new_type("enum","Enum")

sort = true

alias('p',{'param',modifiers={type="$1"}})
alias('ret',{'return',modifiers={type="$1"}})

merge = true
description = 'A game framework for MOAI'
format = 'discount'
backtick_references = false

file = { 
	'.',
	exclude = { '3rdparty'}
}
dir = '../out'
readme = 'README.md'
style = '!pale'
kind_names = {topic = 'Manual',script = 'Programs'}
-- examples  =  {}
