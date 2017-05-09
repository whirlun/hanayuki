%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc supervisor behaviour implement module
%%% @End
%%%====================================================================

-module(ha_sup).
-behaviour(supervisor).

%%API
-export([start_link/0]).

%%supervisor callback
-export([init/1]).


-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    Server = {hanayuki, {hanayuki, start_link, []},
              permanent, 2000, worker, [hanayuki]},
    Index_sup = {ha_index_sup, {ha_index_sup, start_link, []},
    			permanent, 2000, supervisor, [hanayuki]}
    Children = [Server],
    RestartStrategy = {one_for_one, 0, 1},
    {ok, {RestartStrategy, Children}}.