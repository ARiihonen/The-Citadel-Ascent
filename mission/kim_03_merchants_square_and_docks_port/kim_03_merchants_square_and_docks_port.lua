module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

makeAiBlindAndDeaf(true)
moveTime(true)

warpToPosition(VC3(12.548, 24.037, -22.336), 2)
warpToPosition(VC3(-9.371, 25.856, -101.36), 2)
warpToPosition(VC3(27.337, 24.584, -167.63), 2)
idle(10)
testRunToMissionExit(true)
idle(5)
idle(1)