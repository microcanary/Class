local class = {}

function private(t)
  t._containerType = "private"
  return t
end

function public(t)
  t._containerType = "public"
  return t
end

function const(t)
  t._containerType = "constant"
  return t
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function isA(class, name)
  if class.type == name then
    return true
  elseif class.prototype.inherit == "BASE" then
    return false
  else
    return isA(class.prototype.inherit:create(), name)
  end
end

class.cache = {}

class.new = function(prototype)
  prototype = type(prototype) == "string" and class.cache[prototype] or prototype

  prototype = deepcopy(prototype)

  local public = prototype.public
  local private = prototype.private

  public.type = prototype.name

  local mt = {
    __metatable = {};

    __index = function(t, k)
      local value = rawget(public, k)

      if type(value) == "function" then
        return (function(s, ...) return value(prototype.private, ...) end)
      elseif k == "prototype" then
        return prototype
      end

      return value
    end;

    __newindex = function(t, k)
      error("Attempt to add index to class.")
    end;
  }

  setmetatable(prototype.private, mt)

  local class = setmetatable({}, mt)

  return class
end

class.prototype = function(cls)
  local prototype = {}

  prototype.inherit = type(prototype.inherit) == "string" and class.cache[prototype.inherit] or prototype.inherit

  for k, v in pairs(cls) do
    if k == "name" then
      prototype.name = v
      class.cache[v] = prototype
    elseif k == "inherit" then
      prototype.inherit = class.cache[v]
    else
      prototype[v._containerType] = v
    end
  end

  if prototype.inherit then
    for k, v in pairs(prototype.inherit.public) do
      if not prototype.public[k] then
        prototype.public[k] = v
      end
    end

    for k, v in pairs(prototype.inherit.private) do
      if not prototype.private[k] then
        prototype.private[k] = v
      end
    end

  else

    prototype.inherit = "BASE"

  end

  prototype.create = function(self)
    return class.new(self)
  end

  return prototype
end

return class
