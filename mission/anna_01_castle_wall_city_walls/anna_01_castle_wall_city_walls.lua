module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

makeAiBlindAndDeaf(true)
moveTime(true)

warpToPosition(VC3(-36.559, 3.0877, -26.971), 2)
warpToPosition(VC3(-40.842, 3.1961, 35.758), 2)
warpToPosition(VC3(-87.231, 7.0701, 24.524), 2)
warpToPosition(VC3(-131.13, 1.2852, 6.2726), 2)
warpToPosition(VC3(-156.12, -6.9135, 49.698), 2)
idle(5)
testRunToMissionExit(true)
idle(5)
idle(1)