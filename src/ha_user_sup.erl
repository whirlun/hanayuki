%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc user supervisor behaviour implement module
%%% @End
%%%====================================================================

-module(ha_user_sup).
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
	User_helper = {ha_user, {ha_user, start_link, []},
					temporary, brutal_kill, worker, [ha_user]},
	Children = [User_helper],
	RestartStrategy = {simple_one_for_one, 0, 1},
	{ok, {RestartStrategy, Children}}.
