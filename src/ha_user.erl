%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc Index Helper of Hanayuki
%%% @End
%%%====================================================================

-module(ha_user).
-behaviour(gen_server).

%%API
-export ([start_link/0, register/4, login/2, userpage/1, activities/1]).

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
%%@spec register(Username::String() || atom(), Password::String() || atom(), Nickname::String() || atom(), Email::String || atom()) -> {ok, Reply}
%%@End
%%---------------------------------------------------------------------

register(Username, Password, Nickname, Email) ->
	Reply = gen_server:call(?SERVER, {register, Username, Password, Nickname, Email}),
{ok, Reply}.

%%---------------------------------------------------------------------
%%@doc check if a user has correct password
%%@spec login(Username::String() || atom(), Password::String() || atom()) -> {ok, Reply}
%%@End
%%---------------------------------------------------------------------

login(Username, Password) ->
    Reply = gen_server:call(?SERVER, {login, Username, Password}),
    {ok, Reply}.

%%---------------------------------------------------------------------
%%@doc get user's info
%%@spec login(Username::String() || atom()) -> {ok, Reply}
%%@End
%%---------------------------------------------------------------------

userpage(Username) ->
    Reply = gen_server:call(?SERVER, {userpage, Username}),
    {ok, Reply}.

%%---------------------------------------------------------------------
%%@doc get user activities by default option of threads
%%@spec login(Threads::List()) -> {ok, Reply}
%%@End
%%---------------------------------------------------------------------

activities(Threads) ->
    Reply = gen_server:call(?SERVER, {activities, Threads}),
    {ok, Reply}.

%%%====================================================================
%%% callbacks
%%%====================================================================

init([]) ->
	{ok, #state{}}.
	

handle_call({register, Username, Password, Nickname, Email}, _From, State) ->
    case check_register(Username, Email) of
        ok ->case register_helper(Username, Password, Nickname, Email) of 
        ok ->
            {reply, State#state{data=ok}, State};
        error ->
            {reply, State#state{data=error}, State}
        end;
        usernamerepeat -> {reply, State#state{data={[{error, repeatusername}]}}, State};
        emailrepeat -> {reply, State#state{data={[{error, repeatemail}]}}, State}
    end;
handle_call({login, Username, Password}, _From, State) ->
    Result = ha_database:find(user, [username], [Username]),
    case Result of
        {} -> {reply, State#state{data={[{status, nouser}]}}, State};
        {_} -> {{_id,Id,_,_,password,Pass,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}} = Result,
                Pass1 = crypto:hash(sha256, Password),
                case Pass == Pass1 of
                true -> {reply, State#state{data={[{status, verified}, {id, list_to_binary(Id)}]}}, State};
                false -> {reply, State#state{data={[{status, wrongpass}]}}, State}
            end
        end;
handle_call({userpage, Username}, _From, State) ->
    Result = ha_database:find(user, [username], [Username]),
    case Result of
        {} -> {reply, State#state{data={[{status, nouser}]}}, State};
        {_} -> {reply, State#state{data={[{userinfo, userpage_jsonify(Result)}]}}, State}
    end;
handle_call({activities, Username, Page}, _From, State) ->
     = ha_database:activities(user, Username, Page),
    Thread_list = [ha_database:find(user, ['_id'],[T])|| T <- Threads],
    {reply, State#state{data={[{threads, Thread_list}]}}, State}.
    

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

check_register(Username, Email) ->
    Emailreply = ha_database:find(user, [email], [Email]),
    Usernamereply = ha_database:find(user, [username], [Username]),
    case Usernamereply of
        {} -> case Emailreply of
            {} -> ok;
            {_} -> emailrepeat
            end;
        {_} -> usernamerepeat
    end.
register_helper(Username, Password, Nickname, Email) ->
    Pass = crypto:hash(sha256, Password),
    {M, S, _} = os:timestamp(),
	Result = ha_database:insert('user', [username, password, nickname, registertime, threads, loves, signature
    , email, avatar, friends, replies, messages, settings, block, role, badge], 
    [Username, Pass, Nickname, 1000000*M+S,[], [], "", Email, "default.jpg", [], [], [], {needreply, true, neednotice, true, needat, true, 
    blacklist, [], replythreadmode, trace, lovenotice, true, watchlist, [], tracelist,[], watchcat, [], watchtag, [],
    tracetag, [], newpage, true, background, "", cardbackground, ""}, flase, newbee, []]),
	case Result of 
        ok -> 
           ok;
        {error, _} ->
            error
    end.
    
userpage_jsonify(Userinfo) ->
    {{_id,Id,username,Username,_,_,nickname,Nickname,registertime,Registertime,_,_,_,_,signature,Signature,
    email,Email,avatar,Avatar,_,_,_,_,_,_,_,_,block,Block,role,Role,_,_}} = Userinfo,
        {[{id,list_to_binary(Id)}, {username,list_to_binary(Username)},{nickname,list_to_binary(Nickname)},{registerTime,Registertime},
        {signature,list_to_binary(Signature)},{email,list_to_binary(Email)},{avatar,list_to_binary(Avatar)},
        {block,Block},{role,list_to_binary(Role)}]}.

settings_jsonify(Settings) ->
    {needreply, Needreply, neednotice, Neednotice, needat, Needat, blacklist, Blacklist, replythreadmode, Replythreadmode,
    lovenotice, Lovenotice, watchlist, Watchlist, tracelist, Tracelist, watchcat, Watchcat, watchtag, Watchtag,
    tracetag, Tracetag, newpage, Newpage, background, Background, cardbackground, Cardbackground} = Settings,
    {[{needreply, Needreply}, {neednotice, Neednotice}, {needat, Needat}, {blacklist, lists_to_binary(Blacklist,[])}, {replythreadmode, list_to_binary(Replythreadmode)},
    {lovenotice, Lovenotice}, {watchlist, lists_to_binary(Watchlist,[])}, {tracelist, lists_to_binary(Tracelist,[])}, {watchcat, lists_to_binary(Watchcat,[])}, 
    {watchtag,lists_to_binary(Watchtag,[])}, {tracetag, lists_to_binary(Tracetag,[])}, {newpage, Newpage}, {background, list_to_binary(Background)}, {cardbackground, list_to_binary(Cardbackground)}]}.

activities_jsonify([], R) ->
    R;
activities_jsonify([H|T], R) ->
    {}

lists_to_binary([], R) ->
    R;
lists_to_binary([H|T], R) ->
    H1 = list_to_binary(H),
	lists_to_binary(T, [H1|R]).

