%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc Index Helper of Hanayuki
%%% @End
%%%====================================================================

-module(ha_thread).
-behaviour(gen_server).

%%API
-export ([start_link/0, read_thread/1]).

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
%%@spec read_thread(Threadid::Strings()) -> {ok, sent}
%%@End
%%---------------------------------------------------------------------

read_thread(Threadid) ->
    Reply = gen_server:call(?SERVER, {readthread, Threadid}),
    {ok, Reply}.
%%%====================================================================
%%% callbacks
%%%====================================================================

init([]) ->
	{ok, #state{}}.
	

handle_call({readthread, Threadid}, _From, State) ->
	Result = ha_database:find(thread, ["_id"], [Threadid]),
	case Result of 
		{} -> {reply, State#state{data={[{status, nothread}]}}, State};
		{_} -> {reply, State#state{data={[{thread_info, thread_jsonify(Result)}]}}, State}
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

thread_jsonify(Result) ->
	{{'_id',Id,title,Title,content,Content,read,Read,reply,Reply,username, Username, 
	category, Category, rtotal, Rtotal, time, Time, loves, 
	Loves, lock, Lock, accesslevel,Accesslevel}} = Result,
	{[{title, list_to_binary(Title)},{id, list_to_binary(Id)}, {content, list_to_binary(Content)},{read, Read}, {reply, Reply}, {username, list_to_binary(Username)}, {category,list_to_binary(Category)}, {rtotal, Rtotal},{time, Time}, {loves, Loves}, {lock, list_to_binary(Lock)}, {accesslevel, Accesslevel}]}.

lists_to_binary([], R) ->
    R;
lists_to_binary([H|T], R) ->
    H1 = list_to_binary(H),
	lists_to_binary(T, [H1|R]).