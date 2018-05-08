module("autoTesting", package.seeall)
require "autotesting.AutotestingUtils"

idle(5)
pressButton("gamepad_start", 2)
releaseButton("gamepad_start")
openMainMenuItem ("Settings", 0.2, 0.2, 0.5)
loopLanguages(0.5)
backingInMenus(5, 0.2, 0.2, 0.5)
pressButton("gamepad_start", 2)
releaseButton("gamepad_start")
idle(1)
idle(1)