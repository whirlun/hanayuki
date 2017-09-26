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
	%mnesia:init(),
	application:start(xmerl),
	application:start(compiler),
	application:start(syntax_tools),
	application:start(rabbit_common),
	application:ensure_started(amqp_client),
	case ha_sup:start_link() of
		{ok, Pid} -> 
			{ok, Pid};
		{Other} ->
			{error, Other}
	end.

stop(_State) ->
	ok.