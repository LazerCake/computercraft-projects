local matrix = peripheral.wrap("mekanismMachine_3")
if arg[1] == "on" then redstone.setOutput("left", true)
else redstone.setOutput("left", false) end
print("Monitoring...")

while true do
    if matrix.getTotalEnergyFilledPercentage() < 0.5 and not redstone.getOutput("left") then do
        print("Energy low, sending reactor activation signal.")
        redstone.setOutput("left", true)
    end
    elseif matrix.getTotalEnergyFilledPercentage() > 0.9 and redstone.getOutput("left") then do
        print("Energy filled, sending reactor deactivation signal.")
        redstone.setOutput("left", false) end
    end
    os.sleep(10)
end