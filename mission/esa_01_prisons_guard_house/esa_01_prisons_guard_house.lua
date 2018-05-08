module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

makeAiBlindAndDeaf(true)
moveTime(true)

warpToPosition(VC3(9.2938, 25.748, 17.402), 2)
warpToPosition(VC3(35.778, 25.814, 54.576), 2)
warpToPosition(VC3(55.249, 29.875, 30.257), 2)
warpToPosition(VC3(63.171, 29.823, -7.1326), 2)
warpToPosition(VC3(85.598, 37.847, 45.424), 2)
idle(5)
testRunToMissionExit(true)
idle(5)
idle(1)