module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

makeAiBlindAndDeaf(true)
moveTime(true)

warpToPosition(VC3(-19.66, 30.784, 45.669), 2)
warpToPosition(VC3(5.6672, 33.887, 91.641), 2)
warpToPosition(VC3(64.035, 33.793, 83.298), 2)
warpToPosition(VC3(121.1, 23.966, 49.09), 2)
warpToPosition(VC3(180.38, 15.071, 8.3185), 2)
warpToPosition(VC3(235.63, 13.71, -10.5), 2)
warpToPosition(VC3(380.25, 13.714, -24.49), 2)
idle(5)
testRunToMissionExit(true)
idle(5)
idle(1)