local effects = {
    {position = Position(32365, 32237, 7), text = 'TRAINERS', effect = CONST_ME_GROUNDSHAKER},
    {position = Position(32321, 32216, 7), text = 'AREA VIP \n Use', effect = CONST_ME_GROUNDSHAKER},
    {position = Position(32373, 32237, 7), text = 'ROULETTE', effect = 178},    
	    {position = Position(32374, 32232, 7), text = 'SLOT MACHINE', effect = 177},    
			    {position = Position(32523, 32407, 6), text = '', effect = 197},   
			    {position = Position(32524, 32407, 6), text = '', effect = 197}, 
			    {position = Position(32525, 32407, 6), text = '', effect = 197}, 	
			    {position = Position(32524, 32413, 7), text = '', effect = 215}, 					
	 {position = Position(32369, 32245, 7), text = 'TOP 1', effect = 48},  
	 	 {position = Position(32367, 32247, 7), text = 'TOP 2', effect = 12},  
		 	 {position = Position(32371, 32247, 7), text = 'TOP 3', effect = 5},  
}

local animatedText = GlobalEvent("AnimatedText") 
function animatedText.onThink(interval)
    for i = 1, #effects do
        local settings = effects[i]
        local spectators = Game.getSpectators(settings.position, false, true, 7, 7, 5, 5)
        if #spectators > 0 then
            if settings.text then
                for i = 1, #spectators do
                    spectators[i]:say(settings.text, TALKTYPE_MONSTER_SAY, false, spectators[i], settings.position)
                end
            end
            if settings.effect then
                settings.position:sendMagicEffect(settings.effect)
            end
        end
    end
   return true
end

animatedText:interval(4550)
animatedText:register()