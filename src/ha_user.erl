%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc Index Helper of Hanayuki
%%% @End
%%%====================================================================

-module(ha_user).
-behaviour(gen_server).

%%API
-export ([start_link/0, register/4]).

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
%%@doc register a user
%%@spec render_index(Username::String() || atom(), Password::String() || atom(), Nickname::String() || atom(), Email::String || atom()) -> {ok, Reply}
%%@End
%%---------------------------------------------------------------------

register(Username, Password, Nickname, Email) ->
	Reply = gen_server:call(?SERVER, {register, Username, Password, Nickname, Email}),
{ok, Reply}.



%%%====================================================================
%%% callbacks
%%%====================================================================

init([]) ->
	{ok, #state{}}.
	

handle_call({register, Username, Password, Nickname, Email}, _From, State) ->
    Pass = crypto:hash(sha256, Password),
    {M, S, _} = os:timestamp(),
	Result = ha_database:insert('user', [username, password, nickname, registertime, threads, loves, signature
    , email, avatar, friends, replies, messages, settings, block, role], 
    [Username, Pass, Nickname, 1000000*M+S,[], [], "", Email, "default.jpg", [], [], [], {needreply, true, neednotice, true, needat, true, 
    blacklist, [], replythreadmode, trace, lovenotice, true, watchlist, [], tracelist,[], watchcat, [], watchtag, [],
    tracetag, [], newpage, true, background, "transparent.png", cardbackground, "transparent.png"}, flase, newbee]),
	case Result of 
        ok -> 
            {reply, State#state{data=ok}, State};
        {error, _} ->
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

%jsonify([], Result) ->
%	Result1 = lists:reverse(Result),
%	EJson = {[{threads, Result1}]},
%	EJson;
%jsonify([H|T], Result) ->
%	{'_id',_,title,Title,content,_,read,Read,reply,_,username, Username, 
%	category, Category, rtotal, Rtotal, time, Time, loves, 
%	Loves, lock, Lock, accesslevel,Accesslevel} = H,
%	H1 = {[{title, list_to_binary(Title)}, {read, Read}, {reply, Rtotal}, {username, list_to_binary(Username)}, {category,list_to_binary(Category)}, {time, Time}, {loves, Loves}, {lock, Lock}, {accesslevel, Accesslevel}]},
%	jsonify(T, [H1| Result]).
