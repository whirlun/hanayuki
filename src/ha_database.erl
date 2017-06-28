-module(ha_database).

%%API
-export([insert/3, remove/3, find/3, update/4, latest_thread/2, prepare_cache/3]).

-define(DEFAULT_NODE, 'javaNode@BBrabbit-surface').

insert(Setname, Keys, Values) ->
    Result = ha_mongo:insert(?DEFAULT_NODE, Setname, Keys, Values),
    Result.

remove(Setname, Keys, Values) ->
    Result = ha_mongo:remove(?DEFAULT_NODE, Setname, Keys, Values),
    Result.

find(Setname, Keys, Values) ->
    {Status, Result} = ha_mongo:find(?DEFAULT_NODE, Setname, Keys, Values),
    case Status of 
    error -> {error, Result};
    ok -> Result
    end.

update(Setname, Keys, Values, Operation) ->
    Result = ha_mongo:update(?DEFAULT_NODE, Setname, Keys, Values, Operation),
    Result.

latest_thread(Index, Offset) ->
    {Status, Result} = ha_mongo:latest_thread(?DEFAULT_NODE, thread, [], [Index, Offset, a]),
    case Status of 
    error -> {error, Result};
    ok -> Result
    end.

prepare_cache(Index, Offset, UserTime) ->
    {Status, Result} = ha_mongo:prepare_cache(?DEFAULT_NODE, user, [], [Index, Offset, UserTime, a]),
    case Status of
        error -> {error, Result};
        ok -> Result
    end.