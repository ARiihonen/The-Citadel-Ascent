module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

makeAiBlindAndDeaf(true)
moveTime(true)

warpToPosition(VC3(2.5364, 31.801, -58.68), 2)
warpToPosition(VC3(8.003, 35.428, -26.003), 2)
warpToPosition(VC3(29.774, 23.25, 1.3844), 2)
warpToPosition(VC3(-11.268, 25.329, 7.0088), 2)
warpToPosition(VC3(12.446, 27.798, 20.998), 2)
warpToPosition(VC3(-8.1281, 31.25, 45.383), 2)
idle(5)
testRunToMissionExit(true)
idle(5)
idle(1)