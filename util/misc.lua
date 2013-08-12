--[[
Copyright 2012 Rackspace

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]

local math = require('math')
local timer = require('timer')
local table = require('table')
local string = require('string')
local fs = require('fs')
local logging = require('logging')
local utile = require('utile')

function writePid(pidFile, callback)
  if pidFile then
    logging.debug('Writing PID to: ' .. pidFile)
    fs.writeFile(pidFile, tostring(process.pid), function(err)
      if err then
        logging.error('Failed writing PID')
      else
        logging.info('Successfully wrote ' .. pidFile)
      end
      callback(err)
    end)
  else
    callback()
  end
end

function calcJitter(n, jitter)
  return math.floor(n + (jitter * math.random()))
end

function calcJitterMultiplier(n, multiplier)
  local sig = math.floor(math.log10(n)) - 1
  local jitter = multiplier * math.pow(10, sig)
  return math.floor(n + (jitter * math.random()))
end

function nCallbacks(callback, count)
  local n, triggered = 0, false
  return function()
    if triggered then
      return
    end
    n = n + 1
    if count == n then
      triggered = true
      callback()
    end
  end
end

function isNaN(a)
  return tonumber(a) == nil
end

--[[
Compare version strings.
Returns: -1, 0, or 1, if a < b, a == b, or a > b
]]
function compareVersions(a, b)
  local aParts, bParts, pattern, aItem, bItem

  if a == b then
    return 0
  end

  if not a then
    return -1
  end

  if not b then
    return 1
  end

  pattern = '[0-9a-zA-Z]+'
  aParts = utile.split(a, pattern)
  bParts = utile.split(b, pattern)

  aItem = table.remove(aParts, 1)
  bItem = table.remove(bParts, 1)

  while aItem and bItem do
    aItem = tonumber(aItem)
    bItem = tonumber(bItem)
    if not isNaN(aItem) and not isNaN(bItem) then
      if aItem < bItem then
        return -1
      end
      if aItem > bItem then
        return 1
      end
    else
      if isNaN(aItem) then
        return -1
      end
      if isNaN(bItem) then
        return 1
      end
    end
    aItem = table.remove(aParts, 1)
    bItem = table.remove(bParts, 1)
  end

  if aItem then
    return 1
  elseif bItem then
    return -1
  end

  return 0
end


function propagateEvents(fromClass, toClass, eventNames)
  for _, v in pairs(eventNames) do
    fromClass:on(v, function(...)
      toClass:emit(v, ...)
    end)
  end
end


function isStaging()
  if not virgo.config then
    virgo.config = {}
  end
  local b = virgo.config['monitoring_use_staging']
  b = process.env.STAGING or (b and b:lower() == 'true')
  if b then
    process.env.STAGING = 1
  end
  return b
end

--[[ Exports ]]--
local exports = {}
exports.calcJitter = calcJitter
exports.calcJitterMultiplier = calcJitterMultiplier
exports.writePid = writePid
exports.nCallbacks = nCallbacks
exports.compareVersions = compareVersions
exports.propagateEvents = propagateEvents
exports.isStaging = isStaging
exports.randstr = randstr
return exports
