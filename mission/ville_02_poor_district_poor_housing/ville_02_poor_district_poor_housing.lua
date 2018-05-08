module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

makeAiBlindAndDeaf(true)
moveTime(true)

warpToPosition(VC3(-68.915, 33.265, -48.623), 2)
warpToPosition(VC3(-41.826, 25.283, -15.293), 2)
warpToPosition(VC3(-8.6133, 25.523, 22.499), 2)
warpToPosition(VC3(-50.246, 37.097, 75.016), 2)
warpToPosition(VC3(-104.25, 20.92, 46.015), 2)
warpToPosition(VC3(-127.46, 29.156, 110.2), 2)
idle(15)
testRunToMissionExit(true)
idle(5)
idle(1)