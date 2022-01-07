local chatBox = peripheral.wrap("chatBox_0")
local integrator = peripheral.wrap("redstoneIntegrator_2")
local reactor = peripheral.wrap("fissionReactor_0") 
local turbine = peripheral.wrap("turbine_0")
local safe = true
local count = nil

local function redstoneTrigger()
    while true do
        os.pullEvent("redstone")
        if not redstone.getInput("left") then do
            shutdown(7)
            safe = false end
        end
    end
end

local function shutdown(endCode) --shuts down reactor, printing the reason in chat
    reactor.scram()
    safe = false
    local message
    if endCode == 0 then message = "INSUFFICIENT REACTOR COOLANT"
    elseif endCode == 1 then message = "TURBINE STEAM OVERLOAD"
    elseif endCode == 2 then message = "REACTOR WASTE OVERLOAD"
    elseif endCode == 3 then message = "REACTOR HEAT CRITICAL"
    elseif endCode == 4 then message = "REACTOR DAMAGE DETECTED"
    elseif endCode == 5 then message = "REACTOR HEATED COOLANT OVERLOAD"
    elseif endCode == 6 then message = "INSUFFICIENT REACTOR FUEL"
    elseif endCode == 7 then message = "MATRIX ENERGY FILLED"
    else message = "REACTOR ERROR" end
    if endCode ~= 7 then integrator.setOutput("left", true) end
    chatBox.sendMessage(message)
    print(message)
    os.sleep(0.5)
    chatBox.sendMessage("REACTOR SHUTDOWN")
    print("REACTOR SHUTDOWN")
end

local function safeCheck() --test for danger conditions, shut down if true
    local minCoolant, minFuel = 0.9, 0.9
    local maxSteam, maxWaste, maxHeatedCoolant = 0.8, 0.8, 0.8
    local maxTemp = 1000
    local maxDamage = 0.01

    while safe do 
        if reactor.getCoolantFilledPercentage() < minCoolant then shutdown(0)
        elseif turbine.getSteamFilledPercentage() > maxSteam then shutdown(1)
        elseif reactor.getWasteFilledPercentage() > maxWaste then shutdown(2)
        elseif reactor.getTemperature() > maxTemp then shutdown(3)
        elseif reactor.getDamagePercent() > maxDamage then shutdown(4)
        elseif reactor.getHeatedCoolantFilledPercentage() > maxHeatedCoolant then shutdown(5)
        elseif reactor.getFuelFilledPercentage() < minFuel then shutdown(6)
        elseif not redstone.getInput("left") then shutdown(7)
        else os.sleep(1) end
    end
end

local function burnClimb() --slowly increases burn until coolant tank goes down, then decreases burn til it fills again - this should find the maximum safe burn
    while safe do 
        if reactor.getCoolantFilledPercentage() < 0.99 then do
            local refilling = false
            while safe and not refilling do --decrease burn rate until coolant is filling after the decrease
                local coolant1 = reactor.getCoolantFilledPercentage()
                reactor.setBurnRate(reactor.getActualBurnRate() - 0.1)
                os.sleep(0.1)
                local coolant2 = reactor.getCoolantFilledPercentage()
                if(coolant2 > coolant1) then refilling = true end
                print(string.format("Burn down to %.1f...", reactor.getActualBurnRate()))
            end
            break
        end
        elseif reactor.getActualBurnRate() < reactor.getMaxBurnRate() then do --increase burn rate if not at max already
            reactor.setBurnRate(reactor.getActualBurnRate() + 1) 
            print(string.format("Burn up to %.1f...", reactor.getActualBurnRate()))
        end
        elseif count == nil and reactor.getActualBurnRate() == reactor.getMaxBurnRate() then count = os.clock() end --start a 'timer' if at max burn rate
        if count and os.clock() - count >= 30 then break end --if timer has reached set amount, breaks the loop - thus assuming the reactor is stable
        os.sleep(0.5)
    end
    if safe then do 
        print("Stable burn reached.") 
        print("Monitoring...") end
    end
end

local function runReactor() --activate reactor and climb burn rate until max reached or coolant depletes
    reactor.setBurnRate(0)
    print("Burn rate initialised to 0.")
    reactor.activate()
    print("Reactor activated. Initialising checks and burn.")
    parallel.waitForAll(safeCheck, burnClimb)
end

while true do
    if redstone.getInput("left")  then runReactor()
    elseif reactor.getStatus() then shutdown(7)
    else os.sleep(10) end
end