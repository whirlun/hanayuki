-module(ha_database).

%%API
-export([insert/3, remove/3, find/3, update/4, latest_thread/2, prepare_cache/3, 
    activities/2, expand_thread/2, replies/2,loves/2, stars/2]).

%-define(DEFAULT_NODE, lists:concat(['javaNode@', gethostname()])).
-define(DEFAULT_NODE, 'javaNode@bbrabbitsurface').

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

activities(Username, Page) ->
    {Status, Result} = ha_mongo:activities(?DEFAULT_NODE, user, [], [Username, Page]),
    case Status of
        error -> {error, Result};
        ok -> Result
    end.

loves(Username, Page) ->
    {Status, Result} = ha_mongo:loves(?DEFAULT_NODE, user, [], [Username, Page]),
    case Status of
        error -> {error, Result};
        ok -> Result
    end.

stars(Username, Page) ->
    {Status, Result} = ha_mongo:stars(?DEFAULT_NODE, user, [], [Username, Page]),
    case Status of
        error -> {error, Result};
        ok -> Result
    end.

replies(Username, Page) ->
    {Status, Result} = ha_mongo:replies(?DEFAULT_NODE, user, [], [Username, Page]),
    case Status of
        error -> {error, Result};
        ok -> Result
    end.

expand_thread(ThreadId, Content) ->
    Result = ha_mongo:expand_thread(?DEFAULT_NODE, thread, [], [ThreadId, Content]),
    Result.

gethostname() ->
    {ok, Hostname} = inet:gethostname(),
    Hostname.