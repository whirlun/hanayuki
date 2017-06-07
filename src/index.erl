%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc Index Helper of Hanayuki
%%% @End
%%%====================================================================

-module(index).
-behaviour(gen_server).

%%API
-export ([start_link/0, render_index/2, add_thread/4]).

%%gen_server callbacks
-export([init/1, handle_call/3,  handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {data}).
%%%====================================================================
%%% API
%%%====================================================================

%%---------------------------------------------------------------------
%%@doc Start the server
%%@spec start_link() -> {ok, Pid}
%%Where
%%Pid = pid()
%%@End
%%---------------------------------------------------------------------

start_link() ->
	gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


%%---------------------------------------------------------------------
%%@doc give nodejs data to render
%%@spec render_index(Index:: integer(), Offset:: integer) -> {ok, sent}
%%@End
%%---------------------------------------------------------------------

render_index(Index, Offset) ->
	Reply = gen_server:call(?SERVER, {render, Index, Offset}),
{ok, Reply}.

%%---------------------------------------------------------------------
%%@doc give nodejs data to render
%%@spec render_index(Index:: integer(), Offset:: integer) -> {ok, sent}
%%@End
%%---------------------------------------------------------------------

add_thread(Title, Content, Uid, Category) ->
	Reply = gen_server:call(?SERVER, {addthread, Title, Content, Uid, Category}),
	{ok, Reply}.


%%%====================================================================
%%% callbacks
%%%====================================================================

init([]) ->
	{ok, #state{}}.
	

handle_call({render, Index, Offset},_From, State) ->
	Data = ha_database:latest_thread(Index, Offset),
	{data, Result} = Data,
	EJson = jsonify(Result, []),
	{reply, State#state{data = EJson}, State};
handle_call({addthread, Title, Content, Uid, Category}, _From, State) ->
	Result = ha_database:insert('test', [tid, title, content, read, reply, uid, category, rtotal, time, loves, lock, accesslevel],
	[1, Title, Content, 0, 0, Uid, Category, rtotal, time, loves, lock, accesslevel]),
	case Result of
		ok ->
		{reply, State#state{data=ok}, State};
		{error, _}->
		{reply, State#state{data=error}, State}
	end.

handle_cast(stop, State) ->
	{stop, normal, State}.

handle_info(timeout, State) ->
	{ok, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%%%====================================================================
%%% Internal functions
%%%====================================================================

jsonify([], Result) ->
	EJson = {[{threads, Result}]},
	EJson;
jsonify([H|T], Result) ->
	{A,B,C,D,E,F,G,I,J} = H,
	H1 = {[{title, A}, {read, B}, {reply, C}, {username, D}, {category,E}, {time, F}, {loves, G}, {lock, I}, {accesslevel, J}]},
	jsonify(T, [H1| Result]).
