
module ('editor.info', package.seeall)

function majorVersion ()
  return 0
end

function minorVersion ()
  return 1
end

function patchVersion ()
  return 0
end

function version ()
  return majorVersion().."."..minorVersion().."."..patchVersion()
end
