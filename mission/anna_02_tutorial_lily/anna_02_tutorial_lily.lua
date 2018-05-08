module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

makeAiBlindAndDeaf(true)
moveTime(true)

warpToPosition(VC3(-4.7896, -1.3481, 100.93), 2)
warpToPosition(VC3(-47.303, 3.1019, 83.942), 2)
warpToPosition(VC3(-44.799, 1.6298, 61.504), 2)
warpToPosition(VC3(-38.073, 6.2301, 4.4158), 2)
warpToPosition(VC3(-51.54, 6.7809, -41.145), 2)
idle(10)
testRunToMissionExit(true)
idle(5)
idle(1)