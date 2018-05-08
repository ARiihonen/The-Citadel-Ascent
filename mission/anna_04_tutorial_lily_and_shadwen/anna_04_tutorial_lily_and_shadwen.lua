module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

makeAiBlindAndDeaf(true)
moveTime(true)

warpToPosition(VC3(-71.871, -6.5449, 215.67), 2)
warpToPosition(VC3(-91.422, -0.5322, 158.83), 2)
warpToPosition(VC3(-147.83, 7.9087, 128.5), 2)
warpToPosition(VC3(-229.12, 10.727, 95.863), 2)
warpToPosition(VC3(-196.01, 0.2471, 18.42), 2)
warpToPosition(VC3(-209.46, 2.8461, -58.26), 2)
idle(5)
testRunToMissionExit(true)
idle(5)
idle(1)