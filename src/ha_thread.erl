%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc Index Helper of Hanayuki
%%% @End
%%%====================================================================

-module(ha_thread).
-behaviour(gen_server).

%%API
-export ([start_link/0, read_thread/2, reply_thread/4, get_reply/2, like/2, star/2]).

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

reply_thread(Threadid, Content, Username, Threadname) ->
	Reply = gen_server:call(?SERVER, {replythread, Threadid, Content, Username, Threadname}),
	{ok, Reply}.

%%---------------------------------------------------------------------
%%@doc get replies
%%@spec get_reply(Threadid::Strings(), Replylist::List()) -> {ok, sent}
%%@End
%%---------------------------------------------------------------------

get_reply(Threadid, Replylist) ->
	Reply = gen_server:call(?SERVER, {getreply, Threadid, Replylist}),
	{ok, Reply}.

%%---------------------------------------------------------------------
%%@doc add loves
%%@spec get_reply(Threadid::Strings(), Replylist::List()) -> {ok, sent}
%%@End
%%---------------------------------------------------------------------
like(Threadid, Username) ->
	Reply = gen_server:call(?SERVER, {like, Threadid, Username}),
	{ok, Reply}.

%%---------------------------------------------------------------------
%%@doc add stars
%%@spec get_reply(Threadid::Strings(), Replylist::List()) -> {ok, sent}
%%@End
%%---------------------------------------------------------------------
star(Threadid, Username) ->
	Reply = gen_server:call(?SERVER, {star, Threadid, Username}),
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
handle_call({replythread, Threadid, Content, Username, Threadname}, _From, State) ->
	{M, S, _} = os:timestamp(),
	Result = ha_database:insert(reply, [thread, content, username, time, threadname], [Threadid, Content, Username, 1000000*M+S, Threadname]),
	case Result of
		{ok, Id} ->
			ha_database:update(thread, ["_id", reply], [Threadid, Id], "$push"),
			ha_database:update(thread, ["_id", rtotal], [Threadid, 1], "$inc"),
			ha_database:update(user, [username, replies], [Username, Id], "$push"),
			{reply, State#state{data=ok}, State};
		{error, _} ->
			{reply, State#state{data=error}, State}
	end;
handle_call({getreply, Threadid, Replylist}, _From, State) ->
	[Re] = Replylist,
	Reply = [reply_jsonify(ha_database:find(reply, ["_id"], [R]))||R <- string:tokens(binary_to_list(Re), ",")],
	{reply, State#state{data={[{replies,Reply}]}}, State};
handle_call({like, Threadid, Username}, _From, State) ->
	    {{_id,_,username,_,password,_,nickname,_,registertime,_,threads,_,loves,Loves,stars,
    _,signature,_,email,_,avatar,_,friends,_,replies,_,messages,_,settings,_,block,_,role,_,badge,_}} = ha_database:find(user, [username], [Username]),
   	case lists:member(Threadid, Loves) of
   		true -> Result = ha_database:update(user, [username, loves], [Username, Threadid], "$pull"),
   		case Result of
			ok ->{reply, State#state{data=ok}, State};
			{error, _} -> {reply, State#state{data=error}, State}
		end;
   		false -> Result = ha_database:update(user, [username, loves], [Username, Threadid], "$push"),
   		case Result of
   			ok ->  {reply, State#state{data=ok}, State};
   			{error, _} -> {reply, State#state{data=error}, State}
   		end
   	end;
handle_call({star, Threadid, Username}, _From, State) ->
	    {{'_id',_,username,_,password,_,nickname,_,registertime,_,threads,_,loves,_,stars,Stars,
    signature,_,email,_,avatar,_,friends,_,replies,_,messages,_,settings,_,block,_,role,_,badge,_}} = ha_database:find(user, [username], [Username]),
   	case lists:member(Threadid, Stars) of
   		true -> Result = ha_database:update(user, [username, stars], [Username, Threadid], "$pull"),
   		case Result of
			ok ->{reply, State#state{data=ok}, State};
			{error, _} -> {reply, State#state{data=error}, State}
		end;
   		false -> Result = ha_database:update(user, [username, stars], [Username, Threadid], "$push"),
   		case Result of
   			ok ->  {reply, State#state{data=ok}, State};
   			{error, _} -> {reply, State#state{data=error}, State}
   		end
   	end.

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
    {{_id,Id,username,Username,password,_,nickname,Nickname,registertime,Registertime,threads,_,loves,Loves,stars, Stars,signature,Signature,
    email,Email,avatar,Avatar,friends,_,replies,_,messages,_,settings,_,block,Block,role,Role,badge,_}} = Userinfo,
        {[{id,list_to_binary(Id)}, {username,list_to_binary(Username)},{nickname,list_to_binary(Nickname)},{registertime,Registertime},
        {loves, lists_to_binary(Loves,[])}, {stars, lists_to_binary(Stars,[])},
        {signature,list_to_binary(Signature)},{email,list_to_binary(Email)},{avatar,list_to_binary(Avatar)},
        {block,Block},{role,list_to_binary(Role)}]}.

login_jsonify(T) ->
	{{_id,Id,username,Username,_,_,nickname,Nickname,_,_,_,_,_,_,_,_,_,_,_,_,avatar,Avatar,_,_,_,_,_,_,_,_,_,_,_,_,_,_}} = T,
	{[{id, list_to_binary(Id)}, {username, list_to_binary(Username)},{nickname, list_to_binary(Nickname)}, {avatar, list_to_binary(Avatar)}]}.

reply_jsonify(R) ->
	{{_id, Id, thread, _, content, Content,username, Username, time, Time, _, _}} = R,
	{[{id, list_to_binary(Id)}, {username, list_to_binary(Username)}, {content, list_to_binary(Content)}, {time, Time}]}.


lists_to_binary([], R) ->
    R;
lists_to_binary([H|T], R) ->
    H1 = list_to_binary(H),
	lists_to_binary(T, [H1|R]).