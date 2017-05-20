%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc the supervisor of socket communicator
%%% @End
%%%====================================================================

-module(sc_sup).

-behaviour(supervisor).

%%API
-export([start_link/1, start_child/0]).

%% Supervisor callbacks
-export ([init/1]).

-define(SERVER, ?MODULE).

start_link(LSock) ->
	supervisor:start_link({local, ?SERVER}, ?MODULE, [LSock]),
	start_child().

start_child() ->
	supervisor:start_child(?SERVER, []).

init([LSock]) ->
	Server = {sc_server, {sc_server, start_link, [LSock]},
				temporary, brutal_kill, worker, [sc_server]},
	Children = [Server],
	RestartStrategy = {simple_one_for_one, 0, 1},
	{ok, {RestartStrategy, Children}}.