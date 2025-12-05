-- validate_session.lua (production template)
local nk = require('nakama')
local function validate_session(ctx, logger, nk_module, payload)
  logger:info("validate_session called: %s", payload)
  local ok, data = pcall(function() return nk_module.json_decode(payload) end)
  if not ok then error("invalid payload") end
  local token = data.token
  if token == nil then error("missing token") end
  -- Placeholder: return valid=true; implement proper verification in production.
  return nk_module.json_encode({ valid = true, sub = "(unknown)", username = "(unknown)" })
end
local function InitModule(ctx, logger, nk_module, initializer)
  initializer.register_rpc("validate_session", validate_session)
  logger:info("validate_session RPC registered")
end
return InitModule
