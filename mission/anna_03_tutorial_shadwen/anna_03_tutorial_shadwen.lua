module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

makeAiBlindAndDeaf(true)
moveTime(true)

warpToPosition(VC3(130.92, -47.155, 158.66), 2)
warpToPosition(VC3(50.832, -54.853, 81.549), 2)
warpToPosition(VC3(-22.587, 7.0919, 110.82), 2)
warpToPosition(VC3(-23.613, 4.831, 61.902), 2)
warpToPosition(VC3(-34.915, 8.001, -20.743), 2)
idle(10)
testRunToMissionExit(true)
idle(5)
idle(1)