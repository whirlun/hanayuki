%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc Index Helper of Hanayuki
%%% @End
%%%====================================================================

-module(ha_index).
-behaviour(gen_server).

%%API
-export ([start_link/0, render_index/3, add_thread/5, prepare_cache/3, expand_thread/2]).

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

render_index(Index, Offset, Username) ->
	Reply = gen_server:call(?SERVER, {render, Index, Offset, Username},10000),
{ok, Reply}.

%%---------------------------------------------------------------------
%%@doc give nodejs data to render
%%@spec render_index(Index:: integer(), Offset:: integer()) -> {ok, sent}
%%@End
%%---------------------------------------------------------------------

add_thread(Title, Content, Username, Category, Accesslevel) ->
	Reply = gen_server:call(?SERVER, {addthread, Title, Content, Username, Category, Accesslevel}),
	{ok, Reply}.

%%---------------------------------------------------------------------
%%@doc give nodejs data to render
%%@spec prepare_cache(Index:: integer(), Offset:: integer(), Usertime:: Integer()) -> {ok, sent}
%%@End
%%---------------------------------------------------------------------

prepare_cache(Index, Offset, Usertime) ->
	Reply = gen_server:call(?SERVER, {preparecache, Index, Offset, Usertime}),
	{ok, Reply}.

%%---------------------------------------------------------------------
%%@doc give nodejs data to render
%%@spec prepare_cache(ThreadId::String(), Content::String) -> {ok, sent}
%%@End
%%---------------------------------------------------------------------

expand_thread(Threadid, Content) ->
	Reply = gen_server:call(?SERVER, {expandthread, Threadid, Content}),
	{ok, Reply}.
%%%====================================================================
%%% callbacks
%%%====================================================================

init([]) ->
	{ok, #state{}}.
	

handle_call({render, Index, Offset, Username},_From, State) ->
	ThreadResult = ha_database:latest_thread(Index, Offset),
	UserResult = ha_database:find(user,[username], [Username]),
	case Username of
		null ->EJson = {[{threads, render_jsonify(ThreadResult, [])}]};
		_ ->EJson = {[{threads, render_jsonify(ThreadResult, [])}, {userinfo, login_jsonify(UserResult)}]}
	end,
	{reply, State#state{data = EJson}, State};

handle_call({addthread, Title, Content, Username, Category, Accesslevel}, _From, State) ->
	{M, S, _} = os:timestamp(),
	Result = ha_database:insert('thread', [title, content, read, reply, username, category, rtotal, time, loves, lock, accesslevel],
	[Title, Content, 0, [], Username, Category, 0, 1000000*M+S, 0, false, Accesslevel]),
	case Result of
		{ok, Id} ->
		ha_database:update('user', [username, threads], [Username, Id], "$push"),
		{reply, State#state{data={[{status, ok},{threadid, Id}]}}, State};
		{error, _}->
		{reply, State#state{data=error}, State}
	end;
handle_call({expandthread, Threadid, Content}, _From, State) ->
	Result = ha_database:expand_thread(Threadid, Content),
	case Result of
		{ok, _} ->
			{reply, State#state{data=ok}, State};
		{error, _} ->
			{reply, State#state{data=error}, State}
	end;
handle_call({preparecache, Index, Offset, Usertime}, _From, State) ->
	Result = ha_database:prepare_cache(Index, Offset, Usertime),
	{thread, ThreadList, username, UsernameList} = Result,
	Ejson = {[{threads, render_jsonify(ThreadList, [])},{usernames, user_jsonify(UsernameList, [])}]},
	{reply, State#state{data = Ejson}, State}.


handle_cast(stop, State) ->
	{stop, normal, State}.

handle_info(timeout, State) ->
	ha_index_sup:start_child(),
	{ok, State}.

terminate(_Reason, _State) ->
	ha_index_sup:start_child(),
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%%%====================================================================
%%% Internal functions
%%%====================================================================

render_jsonify([], Result) ->
	Result1 = lists:reverse(Result),
	Result1;
render_jsonify([H|T], Result) ->
	{'_id',Id,title,Title,content,_,read,Read,reply,_,username, Username, 
	category, Category, rtotal, Rtotal, time, Time, loves, 
	Loves, lock, Lock, accesslevel,Accesslevel} = H,
	H1 = {[{title, list_to_binary(Title)},{id, list_to_binary(Id)}, {read, Read}, {reply, Rtotal}, {username, list_to_binary(Username)}, {category,list_to_binary(Category)}, {time, Time}, {loves, Loves}, {lock, list_to_binary(Lock)}, {accesslevel, Accesslevel}]},
	render_jsonify(T, [H1| Result]).

user_jsonify([], Result) ->
	Result;
user_jsonify([H|T], Result) ->
	{'_id', _, username, Username, email, Email} = H,
	H1 = {[{username, list_to_binary(Username)}, {email, list_to_binary(Email)}]},
	user_jsonify(T, [H1| Result]).

login_jsonify(T) ->
	{{_id,Id,username,Username,_,_,nickname,Nickname,_,_,_,_,_,_,_,_,_,_,avatar,Avatar,_,_,_,_,_,_,_,_,_,_,_,_,_,_}} = T,
	{[{id, list_to_binary(Id)}, {username, list_to_binary(Username)},{nickname, list_to_binary(Nickname)}, {avatar, list_to_binary(Avatar)}]}.