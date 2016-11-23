module 'mock'

--------------------------------------------------------------------
--Asset
local SupportedSoundAssetTypes = ''
function getSupportedSoundAssetTypes()
	return SupportedSoundAssetTypes
end

function addSupportedSoundAssetType( t )
	if SupportedSoundAssetTypes ~= '' then
		SupportedSoundAssetTypes = SupportedSoundAssetTypes .. ';'
	end
	SupportedSoundAssetTypes = SupportedSoundAssetTypes .. t
end


--------------------------------------------------------------------
require 'mock.audio.FMODDesignerAudioManager'
require 'mock.audio.FMODDesignerProject'

require 'mock.audio.FMODStudioAudioManager'
require 'mock.audio.FMODStudioProject'

--------------------------------------------------------------------
---- Component
require 'mock.audio.SoundSource'
require 'mock.audio.SoundListener'
require 'mock.audio.SoundSourceAnimatorTrack'
