require "input.binds"
require "input.util"

inputModule:setChangeToTouchscreenOnTouch(false)
inputModule:setUseAbsoluteMouseMode(false) -- Snaps the cursor in middle of the screen (like in Quake)
inputModule:setOSCursorVisible(false) -- hide OS cursor at startup


-- NOTE: We use version string format: MAJOR.MINOR.HOTFIX (translates to e.g. 1.0.0)
-- Major will be multiplied with 100, Minor with 10 and hotfix with 1. So 1.0.0 -> 100, 1.0.1 -> 101, 1.1.1 -> 111 etc.
inputUtils:setUserBindsRequiredApplicationVersion(100)


-- Note: Names should be all lowercase

inputUtils:clearICBindsBaseNames()
inputUtils:clearGUIBindsBaseNames()

inputUtils:addICBindsBaseName("thief")
-- Just one set of nameless GUI binds
inputUtils:addGUIBindsBaseName("")
