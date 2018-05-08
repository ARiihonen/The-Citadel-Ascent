module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

makeAiBlindAndDeaf(true)
moveTime(true)

warpToPosition(VC3(-179.07, 3.5859, -29.678), 2)
warpToPosition(VC3(-144.07, 3.5515, 1.1265), 2)
warpToPosition(VC3(-147.77, 3.5921, 53.993), 2)
warpToPosition(VC3(-131.12, 13.509, 68.489), 2)
warpToPosition(VC3(-161.86, 3.5452, 97.996), 2)
warpToPosition(VC3(-180.48, 9.6696, 166.76), 2)
idle(5)
testRunToMissionExit(true)
idle(5)
idle(1)