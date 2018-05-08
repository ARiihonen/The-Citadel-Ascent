-- State machines
require("gameplay.stateCollectionUtils")

-- Animation stuff
require "gameplay.animationUtils"

-- Property connection custom lua expressions
require "gameplay.propertyConnectionUtils"

-- Dummy default scripts
require "data/script/gameplay/dummy/dummy_scripted_state_script.lua"

-- Actors
require "data/root/instance_base/entity/actor/init.lua"

-- Gameplay
require "data/root/instance_base/entity/gameplay/init.lua"

-- Helpers
require "data/root/instance_base/entity/helper/init.lua"

-- Checkpoint
require "gameplay.TrineCheckpointState"

-- Tooltip
require "gameplay.TrineTooltipState"

-- Utils
require "gameplay.util"

require "gameplay.MusicUtil"

require "mission.MissionChangeUtil"

require "gameplay.SecretUnlocks"
require "gameplay.Letters"

gameplay.util.init()