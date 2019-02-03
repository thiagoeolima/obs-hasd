obs           = obslua
source_name   = ""

hymn_number   = ""
current_line  = 1
activated     = false
hymn_lines    = {}
dir_separate  = package.config:sub(1,1)
base_path     = script_path() .. "hymns".. dir_separate

hotkey_id     = obs.OBS_INVALID_HOTKEY_ID

function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

function lines_from(file)
  if not file_exists(file) then
    return {}
  end
  lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end


function load_hymn()
  local file = base_path .. hymn_number .. ".TXT"
  hymn_lines = lines_from(file)
  current_line = 1
  local source = obs.obs_get_source_by_name(source_name)
  if source ~= nil then
    local settings = obs.obs_data_create()
    obs.obs_data_set_string(settings, "text", text)
    obs.obs_source_update(source, settings)
    obs.obs_data_release(settings)
    obs.obs_source_release(source)
  end
end

function set_text()

  text = hymn_lines[current_line]

  local source = obs.obs_get_source_by_name(source_name)
  if source ~= nil then
    local settings = obs.obs_data_create()
    obs.obs_data_set_string(settings, "text", text)
    obs.obs_source_update(source, settings)
    obs.obs_data_release(settings)
    obs.obs_source_release(source)
  end

end

function activate(activating)
  if activated == activating then
    return
  end

  activated = activating
  load_hymn()
  set_text()

end

-- Called when a source is activated/deactivated
function activate_signal(cd, activating)
  local source = obs.calldata_source(cd, "source")
  if source ~= nil then
    local name = obs.obs_source_get_name(source)
    if (name == source_name) then
      activate(activating)
    end
  end
end

function source_activated(cd)
  activate_signal(cd, true)
end

function source_deactivated(cd)
  activate_signal(cd, false)
end

function reset(pressed)
  if not pressed then
    return
  end
  activate(false)
  local source = obs.obs_get_source_by_name(source_name)
  if source ~= nil then
    local active = obs.obs_source_active(source)
    obs.obs_source_release(source)
    activate(active)
  end
end

function reset_button_clicked(props, p)
  current_line = 1
  reset(true)
  return false
end

function next_button_clicked(props, p)
  if current_line < #hymn_lines then
    current_line = current_line + 1
    set_text()
  end
  return false
end


function back_button_clicked(props, p)
  if current_line > 1 then
    current_line = current_line - 1
    set_text()
  end
  return false
end

----------------------------------------------------------

-- A function named script_properties defines the properties that the user
-- can change for the entire script module itself
function script_properties()
  local props = obs.obs_properties_create()

  local p = obs.obs_properties_add_list(props, "source", "Camada do Texto", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
  local sources = obs.obs_enum_sources()
  if sources ~= nil then
    for _, source in ipairs(sources) do
      source_id = obs.obs_source_get_id(source)
      if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
        local name = obs.obs_source_get_name(source)
        obs.obs_property_list_add_string(p, name, name)
      end
    end
  end
  obs.source_list_release(sources)

  local hymn = obs.obs_properties_add_list(props, "hymn_number", "Hino", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)

  local pdir = io.popen('find "'..base_path..'" -type f')  --Open directory look for files, save data in p. By giving '-type f' as parameter, it returns all files.

  for file in pdir:lines() do                         --Loop through all files
    local file_local =  file:sub(base_path:len()+1,file:len())
    local file_name  =  file_local:sub(0,file_local:len()-4)
    obs.obs_property_list_add_string(hymn, file_name, file_local)
  end
  


  obs.obs_properties_add_button(props, "reset_button", "Resetar/Iniciar", reset_button_clicked)
  obs.obs_properties_add_button(props, "back_button", "Voltar", back_button_clicked)
  obs.obs_properties_add_button(props, "next_button", "Avançar", next_button_clicked)

  return props
end

-- A function named script_description returns the description shown to
-- the user
function script_description()
  return "Hinário Adventista do Sétimo Dia. \n \nMade by Thiago Lima "
end

-- A function named script_update will be called when settings are changed
function script_update(settings)
  activate(false)
  source_name = obs.obs_data_get_string(settings, "source")
  hymn_number = obs.obs_data_get_string(settings, "hymn_number")
  reset(true)
end

-- A function named script_defaults will be called to set the default settings
function script_defaults(settings)
--obs.obs_data_set_default_string(settings, "hymn_number", "001")
end

-- A function named script_save will be called when the script is saved
--
-- NOTE: This function is usually used for saving extra data (such as in this
-- case, a hotkey's save data).  Settings set via the properties are saved
-- automatically.
function script_save(settings)
  local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
  obs.obs_data_set_array(settings, "reset_hotkey", hotkey_save_array)
  obs.obs_data_array_release(hotkey_save_array)
end

-- a function named script_load will be called on startup
function script_load(settings)
  -- Connect hotkey and activation/deactivation signal callbacks
  --
  -- NOTE: These particular script callbacks do not necessarily have to
  -- be disconnected, as callbacks will automatically destroy themselves
  -- if the script is unloaded.  So there's no real need to manually
  -- disconnect callbacks that are intended to last until the script is
  -- unloaded.
  local sh = obs.obs_get_signal_handler()
  obs.signal_handler_connect(sh, "source_activate", source_activated)
  obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)

  hotkey_id = obs.obs_hotkey_register_frontend("reset_timer_thingy", "Resetar/Iniciar", reset)
  local hotkey_save_array = obs.obs_data_get_array(settings, "reset_hotkey")
  obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
  obs.obs_data_array_release(hotkey_save_array)
end
