%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc mongodb module of hanayuki
%%% @End
%%%====================================================================

-module(ha_mongo).

-export([insert/4, remove/4, update/5, find/4, latest_thread/4, prepare_cache/4]).

insert(Node, Setname, Keys, Values) ->
    Ref = make_ref(),  
    {mongo_server, Node} ! {insert, self(), Ref,Setname, Keys, Values},
    receive
        {reply, ok, Ref} ->
        ok;
        {reply, error, Ref} ->
        {error, internalerror}
    after 3000 ->
        {error, timeout}
    end.

remove(Node, Setname, Keys, Values) ->
    Ref = make_ref(),
    {mongo_server, Node} ! {remove, self(), Ref, Setname, Keys, Values},
    receive
        {reply, ok, Ref} ->
        ok;
        {reply, error, Ref} ->
            {error, internalerror}
    after 3000 ->
        {error, timeout}
    end.

find(Node, Setname, Keys, Values) ->
    Ref = make_ref(),
    {mongo_server, Node} ! {find, self(), Ref, Setname, Keys, Values},
    receive
        {reply, ok, Result, Ref} ->
        {ok, Result};
        {reply, error, Ref} ->
            {error, internalerror}
    after 3000 ->
        {error, timeout}
    end.

update(Node, Setname, Keys, Values, Operation) ->
    Ref = make_ref(),
    {mongo_server, Node} ! {update, self(), Ref, Setname, Keys, Values, Operation},
    receive
        {reply, ok, Ref} ->
        ok;
        {reply, error, Ref} ->
            {error, internalerror}
    after 3000 ->
        {error, timeout}
    end.

latest_thread(Node, Setname, Keys, Values) ->
    Ref = make_ref(),
    {mongo_server, Node} ! {latestthread, self(), Ref, Setname, Keys, Values},
    receive
        {reply, ok, Result, Ref} ->
            {ok, Result};
        {reply, error, Ref} ->
            {error, internalerror}
    after 3000 ->
        {error, timeout}
    end.

prepare_cache(Node, Setname, Keys, Values) ->
    Ref = make_ref(),
    {mongo_server, Node} ! {preparecache, self(), Ref, Setname, Keys, Values},
    receive
        {reply, ok, Result, Ref} ->
            {ok, Result};
        {reply, error, Ref} ->
            {error, internalerror}
    after 30000 ->
        {error, timeout}
    end.