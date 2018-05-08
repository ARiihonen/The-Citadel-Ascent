module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

makeAiBlindAndDeaf(true)
moveTime(true)

warpToPosition(VC3(27.565, -75.081, 51.136), 2)
warpToPosition(VC3(40.243, -66.967, 86.902), 2)
warpToPosition(VC3(14.058, -72.168, 143.84), 2)
warpToPosition(VC3(-45.345, -72.923, 166.82), 2)
warpToPosition(VC3(-108.22, -70.039, 127.53), 2)
warpToPosition(VC3(-160.32, -60.737, 127.94), 2)
idle(5)
testRunToMissionExit(true)
idle(5)
idle(1)