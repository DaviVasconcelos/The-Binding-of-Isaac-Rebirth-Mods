local mod = RegisterMod("R Key Hold", 1)
local R_KEY_ID = CollectibleType.COLLECTIBLE_R_KEY
local holdCounter = 0
local HOLD_TIME = 5

function mod:OnUpdate()
    if not Input.IsButtonPressed(Keyboard.KEY_R, 0) then
        holdCounter = 0
        return 
    end

    local player = Isaac.GetPlayer(0)
    if not player then return end

    if player:HasCollectible(R_KEY_ID) then
        holdCounter = holdCounter + 1

        if holdCounter >= HOLD_TIME then
            player:UseActiveItem(R_KEY_ID, false, false, true, false)
            player:RemoveCollectible(R_KEY_ID)
            holdCounter = 0
        end
    else
        holdCounter = 0
    end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.OnUpdate)