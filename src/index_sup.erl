%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc index supervisor behaviour implement module
%%% @End
%%%====================================================================

-module(index_sup).
-behaviour(supervisor).

%%API
-export([start_link/0, start_child/0]).

%%supervisor callback
-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []),
    start_child().

start_child() ->
	supervisor:start_child(?SERVER, []).

init([]) ->
	IndexHelper = {index, {index, start_link, []},
					temporary, brutal_kill, worker, [index]},
	Children = [IndexHelper],
	RestartStrategy = {simple_one_for_one, 0, 1},
	{ok, {RestartStrategy, Children}}.
