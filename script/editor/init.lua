
require "editor.Util"
require "editor.Editor"
require "editor.ExternalUI"
require "editor.TypeManagerWrapper"
require "editor.ObjectVisibility"
require "editor.EditorTypes"
require "editor.Plugin"
require "editor.CategoryCommon"
require "editor.ParticleSystems"

editor.Util.initUtil()
editor.Editor.initEditor()
editor.ExternalUI.initExternalUI()

function reloadEditorScripts()
  require "editor.Util"
  require "editor.Editor"
  require "editor.ExternalUI"
  require "editor.TypeManagerWrapper"
  require "editor.ObjectVisibility"
  require "editor.EditorTypes"
	require "editor.Plugin"
  require "editor.CategoryCommon"
  require "editor.ParticleSystems"
  reloadScripts()
end
