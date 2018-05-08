module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

makeAiBlindAndDeaf(true)
moveTime(true)

idle(15)
testRunToMissionExit(true)
idle(5)
idle(1)