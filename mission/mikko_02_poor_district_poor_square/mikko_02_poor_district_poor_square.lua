module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

makeAiBlindAndDeaf(true)
moveTime(true)

warpToPosition(VC3(15.245, 22.358, -18.89), 2)
warpToPosition(VC3(-3.495, 26.373, -47.509), 2)
warpToPosition(VC3(-13.236, 29.948, -110.15), 2)
warpToPosition(VC3(22.36, 28.19, -122.1), 2)
warpToPosition(VC3(93.518, 22.27, -112.31), 2)
warpToPosition(VC3(147.5, 22.311, -112), 2)
idle(5)
testRunToMissionExit(true)
idle(5)
idle(1)