%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc application behaviour implementation module
%%% @End
%%%====================================================================

-module(ha_app).
-behaviour(application).

%%application callback
-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
	mnesia:init(),
	case ha_sup:start_link() of
		{ok, Pid} -> 
			{ok, Pid};
		{Other} ->
			{error, Other}
	end.

stop(_State) ->
	ok.