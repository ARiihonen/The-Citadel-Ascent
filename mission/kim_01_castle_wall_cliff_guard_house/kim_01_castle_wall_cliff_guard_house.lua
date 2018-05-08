module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

makeAiBlindAndDeaf(true)
moveTime(true)

warpToPosition(VC3(64.734, -78.54, 98.601), 2)
warpToPosition(VC3(25.048, -68.456, 107.4), 2)
warpToPosition(VC3(-14.303, -76.456, 161.89), 2)
warpToPosition(VC3(-53.306, -64.456, 145.37), 2)
warpToPosition(VC3(-45.86, -76.456, 181.85), 2)
idle(5)
testRunToMissionExit(true)
idle(5)
idle(1)