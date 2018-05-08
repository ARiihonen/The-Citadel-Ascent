module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

makeAiBlindAndDeaf(true)
moveTime(true)

warpToPosition(VC3(-45.759, -74.881, 182.88), 2)
warpToPosition(VC3(-17.393, -69.705, 144.65), 2)
idle(12)
testRunToMissionExit(true)
idle(5)
idle(1)