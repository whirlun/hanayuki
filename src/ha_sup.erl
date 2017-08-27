%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc root supervisor behaviour implement module
%%% @End
%%%====================================================================

-module(ha_sup).
-behaviour(supervisor).

%%API
-export([start_link/0]).

%%supervisor callback
-export([init/1]).


-define(SERVER, ?MODULE).
-define(DEFAULT_PORT, 2333).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
	Port = case application:get_env(tcp_interface, port) of
		{ok, P} -> P;
		undefined -> ?DEFAULT_PORT
	end,
	{ok, LSock} = gen_tcp:listen(Port, [{active, true}]),
	Socket_sup = {ha_sc_sup, {ha_sc_sup, start_link, [LSock]},
				permanent, 2000, supervisor, [ha_sc_server]},
    Index_sup = {ha_index_sup, {ha_index_sup, start_link, []},
    			permanent, 2000, supervisor, [ha_index]},
	User_sup = {ha_user_sup, {ha_user_sup, start_link, []},
				permanent, 2000, supervisor, [ha_user]},
	Thread_sup = {ha_thread_sup, {ha_thread_sup, start_link, []},
				permanent, 2000, supervisor, [ha_thread]},
    Children = [Socket_sup, Index_sup, User_sup, Thread_sup],
    RestartStrategy = {one_for_one, 0, 1},
    {ok, {RestartStrategy, Children}}.