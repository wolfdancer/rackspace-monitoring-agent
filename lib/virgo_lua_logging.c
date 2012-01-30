/*
 *  Copyright 2011 Rackspace
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#include "virgo.h"
#include "virgo__types.h"
#include "virgo__lua.h"

#define LOGGINGHANDLE "virgo.logging"

static int
logging_log(lua_State *L) {
  const char *msg;
  unsigned int loglevel = 0;
  virgo_t *v = virgo__lua_context(L);
  loglevel = luaL_checknumber(L, 1);
  
  if (virgo_log_level_get(v) < loglevel) {
    return 0;
  }

  msg = luaL_checkstring(L, 2);

  virgo_log(v, loglevel, msg);

  return 0;
}

int
virgo__lua_logging_open(lua_State *L)
{
  lua_newtable(L);

  lua_pushcfunction(L, logging_log);
  lua_setfield(L, -2, "log");

  VIRGO_DEFINE_CONSTANT(L, VIRGO_LOG_NOTHING);
  VIRGO_DEFINE_CONSTANT_ALIAS(L, VIRGO_LOG_NOTHING, "NOTHING");
  VIRGO_DEFINE_CONSTANT(L, VIRGO_LOG_CRITICAL);
  VIRGO_DEFINE_CONSTANT_ALIAS(L, VIRGO_LOG_CRITICAL, "CRITICAL");
  VIRGO_DEFINE_CONSTANT_ALIAS(L, VIRGO_LOG_CRITICAL, "CRIT");
  VIRGO_DEFINE_CONSTANT(L, VIRGO_LOG_ERRORS);
  VIRGO_DEFINE_CONSTANT_ALIAS(L, VIRGO_LOG_ERRORS, "ERROR");
  VIRGO_DEFINE_CONSTANT_ALIAS(L, VIRGO_LOG_ERRORS, "ERR");
  VIRGO_DEFINE_CONSTANT(L, VIRGO_LOG_WARNINGS);
  VIRGO_DEFINE_CONSTANT_ALIAS(L, VIRGO_LOG_WARNINGS, "WARNING");
  VIRGO_DEFINE_CONSTANT_ALIAS(L, VIRGO_LOG_WARNINGS, "WARN");
  VIRGO_DEFINE_CONSTANT(L, VIRGO_LOG_INFO);
  VIRGO_DEFINE_CONSTANT_ALIAS(L, VIRGO_LOG_INFO, "INFO");
  VIRGO_DEFINE_CONSTANT(L, VIRGO_LOG_DEBUG);
  VIRGO_DEFINE_CONSTANT_ALIAS(L, VIRGO_LOG_DEBUG, "DEBUG");
  VIRGO_DEFINE_CONSTANT_ALIAS(L, VIRGO_LOG_DEBUG, "DBG");
  VIRGO_DEFINE_CONSTANT(L, VIRGO_LOG_EVERYTHING);
  VIRGO_DEFINE_CONSTANT_ALIAS(L, VIRGO_LOG_EVERYTHING, "EVERYTHING");

  return 1;
}