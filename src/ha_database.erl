-module(ha_database).

%%API
-export([insert/3, remove/3, find/3, update/4, latest_thread/2]).

-define(DEFAULT_NODE, 'javaNode@BBrabbit-surface').

insert(Setname, Keys, Values) ->
    ha_mnesia:insert_thread(Values),
    Result = ha_mongo:insert(?DEFAULT_NODE, Setname, Keys, Values),
    Result.

remove(Setname, Keys, Values) ->
    Result = ha_mongo:remove(?DEFAULT_NODE, Setname, Keys, Values),
    Result.

find(Setname, Keys, Values) ->
    {ok, Result} = ha_mongo:find(?DEFAULT_NODE, Setname, Keys, Values),
    Result.

update(Setname, Keys, Values, Operation) ->
    Result = ha_mongo:update(Setname, Keys, Values, Operation),
    Result.

latest_thread(Index, Offset) ->
    {data, Data} = ha_mnesia:lookup_latestThread(Index, Offset),
    Data.