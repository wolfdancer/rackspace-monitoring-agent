local table = require('table')
local async = require('async')
local ConnectionStream = require('/base/client/connection_stream').ConnectionStream
local misc = require('/base/util/misc')
local helper = require('../helper')
local timer = require('timer')
local consts = require('/constants')
local Endpoint = require('../../endpoint').Endpoint
local path = require('path')
local os = require('os')

local exports = {}

exports['test_handshake_timeout'] = function(test, asserts)
  local AEP, options, endpoints, client

  if os.type() == "win32" then
    test.skip("Skip test_handshake_timeout until a suitable SIGUSR1 replacement is used in runner.py")
    return nil
  end

  options = {
    datacenter = 'test',
    tls = { rejectUnauthorized = false }
  }

  endpoints = { Endpoint:new(TESTING_AGENT_ENDPOINTS[1]) }
  client = ConnectionStream:new('id', 'token', 'guid', false, options)

  async.series({
    function(callback)
      local serverOptions = {
        env = { RATE_LIMIT = 0 } 
      }
      AEP = helper.start_server(serverOptions, callback)
    end,
    function(callback)
      client:createConnections(endpoints, callback)
    end,
    function(callback)
      client:once('reconnect', callback)
    end
  }, function()
    AEP:kill(9)
    test.done()
  end)
end

exports['test_reconnects'] = function(test, asserts)
  local AEP

  if os.type() == "win32" then
    test.skip("Skip test_reconnects until a suitable SIGUSR1 replacement is used in runner.py")
    return nil
  end

  local options = {
    datacenter = 'test',
    stateDirectory = './tests',
    tls = { rejectUnauthorized = false }
  }

  local client = ConnectionStream:new('id', 'token', 'guid', false, options)

  local clientEnd = 0
  local reconnect = 0

  client:on('client_end', function(err)
    clientEnd = clientEnd + 1
  end)

  client:on('reconnect', function(err)
    reconnect = reconnect + 1
  end)

  local endpoints = {}
  for _, address in pairs(TESTING_AGENT_ENDPOINTS) do
    -- split ip:port
    table.insert(endpoints, Endpoint:new(address))
  end

  async.series({
    function(callback)
      AEP = helper.start_server(callback)
    end,
    function(callback)
      client:on('handshake_success', misc.nCallbacks(callback, 3))
      local endpoints = {}
      for _, address in pairs(TESTING_AGENT_ENDPOINTS) do
        -- split ip:port
        table.insert(endpoints, Endpoint:new(address))
      end
      client:createConnections(endpoints, function() end)
    end,
    function(callback)
      AEP:kill(9)
      client:on('reconnect', misc.nCallbacks(callback, 3))
    end,
    function(callback)
      AEP = helper.start_server(function()
        client:on('handshake_success', misc.nCallbacks(callback, 3))
      end)
    end,
  }, function()
    AEP:kill(9)
    asserts.ok(clientEnd > 0)
    asserts.ok(reconnect > 0)
    test.done()
  end)
end

exports['test_upgrades'] = function(test, asserts)
  local options, client, endpoints

  if true then
    test.skip("Skip upgrades test until it is reliable")
    return nil
  end

  -- Override the default download path
  consts:setGlobal('DEFAULT_DOWNLOAD_PATH', path.join('.', 'tmp'))

  options = {
    datacenter = 'test',
    stateDirectory = './tests',
    tls = { rejectUnauthorized = false }
  }

  local endpoints = {}
  for _, address in pairs(TESTING_AGENT_ENDPOINTS) do
    -- split ip:port
    table.insert(endpoints, Endpoint:new(address))
  end

  async.series({
    function(callback)
      AEP = helper.start_server(callback)
    end,
    function(callback)
      client = ConnectionStream:new('id', 'token', 'guid', false, options)
      client:once('error', callback)
      client:createConnections(endpoints, function() end)
    end,
  }, function()
    AEP:kill(9)
    client:done()
    test.done()
  end)
end

return exports
