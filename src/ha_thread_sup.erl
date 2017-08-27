%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc index supervisor behaviour implement module
%%% @End
%%%====================================================================

-module(ha_thread_sup).
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
	Thread_helper = {ha_thread, {ha_thread, start_link, []},
					temporary, brutal_kill, worker, [ha_thread]},
	Children = [Thread_helper],
	RestartStrategy = {simple_one_for_one, 0, 1},
	{ok, {RestartStrategy, Children}}.
