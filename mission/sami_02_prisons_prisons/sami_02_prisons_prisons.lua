module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

makeAiBlindAndDeaf(true)
moveTime(true)

warpToPosition(VC3(-34.599, 1.0967, 126.26), 2)
warpToPosition(VC3(-56.415, 1.0782, 109.94), 2)
warpToPosition(VC3(-14.517, 5.0964, 65.014), 2)
warpToPosition(VC3(-47.586, 9.0283, 38.045), 2)
warpToPosition(VC3(-86.593, 16.776, 79.309), 2)
warpToPosition(VC3(-88.975, 25.097, 116.47), 2)
idle(5)
testRunToMissionExit(true)
idle(5)
idle(1)