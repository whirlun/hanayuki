%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc Index Helper of Hanayuki
%%% @End
%%%====================================================================

-module(ha_thread).
-behaviour(gen_server).

%%API
-export ([start_link/0, read_thread/2, reply_thread/3, get_reply/2]).

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

read_thread(Threadid, Username) ->
    Reply = gen_server:call(?SERVER, {readthread, Threadid, Username}),
    {ok, Reply}.

%%---------------------------------------------------------------------
%%@doc give nodejs data to render
%%@spec read_thread(Threadid::Strings(), Content::String(), Username::Atom()||String()) -> {ok, sent}
%%@End
%%---------------------------------------------------------------------

reply_thread(Threadid, Content, Username) ->
	Reply = gen_server:call(?SERVER, {replythread, Threadid, Content, Username}),
	{ok, Reply}.

%%---------------------------------------------------------------------
%%@doc get replies
%%@spec get_reply(Threadid::Strings(), Replylist::List()) -> {ok, sent}
%%@End
%%---------------------------------------------------------------------

get_reply(Threadid, Replylist) ->
	Reply = gen_server:call(?SERVER, {getreply, Threadid, Replylist}),
	{ok, Reply}.
%%%====================================================================
%%% callbacks
%%%====================================================================

init([]) ->
	{ok, #state{}}.
	

handle_call({readthread, Threadid, Username1}, _From, State) ->
	Result = ha_database:find(thread, ["_id"], [Threadid]),
	UserResult = ha_database:find(user,[username], [Username1]),
	case Result of 
		{} -> {reply, State#state{data={[{status, nothread}]}}, State};
		{_} -> 
			{Result1, Username} = thread_jsonify(Result),
			UserInfo = ha_database:find(user, ["username"], [Username]),
			case Username1 of
			null -> 
				{reply, State#state{data={[{thread_info, Result1} ,{user_info, userpage_jsonify(UserInfo)}]}}, State};
			_ ->
				{reply, State#state{data={[{thread_info, Result1} ,{user_info, userpage_jsonify(UserInfo)}, {userinfo, login_jsonify(UserResult)}]}}, State}
			end
	end;
handle_call({replythread, Threadid, Content, Username}, _From, State) ->
	{M, S, _} = os:timestamp(),
	Result = ha_database:insert(reply, [thread, content, username, time], [Threadid, Content, Username, 1000000*M+S]),
	case Result of
		{ok, Id} ->
			ha_database:update(thread, ["_id", reply], [Threadid, Id], "$push"),
			ha_database:update(thread, ["_id", rtotal], [Threadid, 1], "$inc"),
			{reply, State#state{data=ok}, State};
		{error, _} ->
			{reply, State#state{data=error}, State}
	end;
handle_call({getreply, Threadid, Replylist}, _From, State) ->
	[Re] = Replylist,
	Reply = [reply_jsonify(ha_database:find(reply, ["_id"], [binary_to_list(R)]))||R <- string:split(Re, ",")],
	{reply, State#state{data={[{replies,Reply}]}}, State}.

handle_cast(stop, State) ->
	{stop, normal, State}.

handle_info(timeout, State) ->
	ha_thread_sup:start_child(),
	{ok, State}.

terminate(_Reason, _State) ->
	ha_thread_sup:start_child(),
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
	{{[{title, list_to_binary(Title)},{id, list_to_binary(Id)}, {content, list_to_binary(Content)},{read, Read}, {reply, lists_to_binary(Reply, [])}, {username, list_to_binary(Username)}, {category,list_to_binary(Category)}, {rtotal, Rtotal},{time, Time}, {loves, Loves}, {lock, list_to_binary(Lock)}, {accesslevel, Accesslevel}]}, Username}.

userpage_jsonify(Userinfo) ->
    {{_id,Id,username,Username,_,_,nickname,Nickname,registertime,Registertime,threads,Threads,_,_,signature,Signature,
    email,Email,avatar,Avatar,_,_,replies,Replies,_,_,_,_,block,Block,role,Role,_,_}} = Userinfo,
        {[{id,list_to_binary(Id)}, {username,list_to_binary(Username)},{nickname,list_to_binary(Nickname)},{registertime,Registertime},
        {threadcount, length(Threads)},{replycount, length(Replies)},
        {signature,list_to_binary(Signature)},{email,list_to_binary(Email)},{avatar,list_to_binary(Avatar)},
        {block,Block},{role,list_to_binary(Role)}]}.

login_jsonify(T) ->
	{{_id,Id,username,Username,_,_,nickname,Nickname,_,_,_,_,_,_,_,_,_,_,avatar,Avatar,_,_,_,_,_,_,_,_,_,_,_,_,_,_}} = T,
	{[{id, list_to_binary(Id)}, {username, list_to_binary(Username)},{nickname, list_to_binary(Nickname)}, {avatar, list_to_binary(Avatar)}]}.

reply_jsonify(R) ->
	{{_id, Id, thread, _, content, Content,username, Username, time, Time}} = R,
	{[{id, list_to_binary(Id)}, {username, list_to_binary(Username)}, {content, list_to_binary(Content)}, {time, Time}]}.


lists_to_binary([], R) ->
    R;
lists_to_binary([H|T], R) ->
    H1 = list_to_binary(H),
	lists_to_binary(T, [H1|R]).