%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc Index Helper of Hanayuki
%%% @End
%%%====================================================================

-module(ha_user).
-behaviour(gen_server).

%%API
-export ([start_link/0, register/4, login/2, userpage/1, activities/2, replies/2, loves/2, stars/2]).

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
%%@spec userpage(Username::String() || atom()) -> {ok, Reply}
%%@End
%%---------------------------------------------------------------------

userpage(Username) ->
    Reply = gen_server:call(?SERVER, {userpage, Username}),
    {ok, Reply}.

%%---------------------------------------------------------------------
%%@doc get user activities by default option of threads
%%@spec activities(Username::String() || atom(), Page::Integer()) -> {ok, Reply}
%%@End
%%---------------------------------------------------------------------

activities(Username, Page) ->
    Reply = gen_server:call(?SERVER, {activities, Username, Page}),
    {ok, Reply}.

%%---------------------------------------------------------------------
%%@doc get user replies
%%@spec login(Threads::List()) -> {ok, Reply}
%%@End
%%---------------------------------------------------------------------

replies(Username, Page) ->
    Reply = gen_server:call(?SERVER, {replies, Username, Page}),
    {ok, Reply}.

%%---------------------------------------------------------------------
%%@doc get user lovelist
%%@spec loves(Username::String() || Atom(), Page::Integer()) -> {ok, Reply}
%%@End
%%---------------------------------------------------------------------

loves(Username, Page) ->
    Reply = gen_server:call(?SERVER, {loves, Username, Page}),
    {ok, Reply}.

%%---------------------------------------------------------------------
%%@doc get user starlist
%%@spec stars(Username::String() || Atom(), Page::Integer()) -> {ok, Reply}
%%@End
%%---------------------------------------------------------------------

stars(Username, Page) ->
    Reply = gen_server:call(?SERVER, {stars, Username, Page}),
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
        {_} -> {{_id,Id,_,_,password,Pass,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}} = Result,
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
    Thread_list = ha_database:activities(Username, Page),
    Result = activities_jsonify(Thread_list, []),
    {reply, State#state{data={[{threads, Result}]}}, State};
handle_call({loves, Username, Page}, _From, State) ->
    Thread_list = ha_database:loves(Username, Page),
    Result = activities_jsonify(Thread_list, []),
    {reply, State#state{data={[{loves, Result}]}}, State};
handle_call({stars, Username, Page}, _From, State) ->
    Thread_list = ha_database:stars(Username, Page),
    Result = activities_jsonify(Thread_list, []),
    {reply, State#state{data={[{stars, Result}]}}, State};
handle_call({replies, Username, Page}, _From, State) ->
    Reply_list = ha_database:replies(Username, Page),
    Result = replies_jsonify(Reply_list, []),
    {reply, State#state{data={[{replies, Result}]}}, State}.
    

handle_cast(stop, State) ->
	{stop, normal, State}.

handle_info(timeout, State) ->
    ha_user_sup:start_child(),
	{ok, State}.

terminate(_Reason, _State) ->
    ha_user_sup:start_child(),
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
	Result = ha_database:insert('user', [username, password, nickname, registertime, threads, loves, stars, signature
    , email, avatar, friends, replies, messages, settings, block, role, badge], 
    [Username, Pass, Nickname, 1000000*M+S,[], [], [], "", Email, "default.jpg", [], [], [], {needreply, true, neednotice, true, needat, true, 
    blacklist, [], replythreadmode, trace, lovenotice, true, watchlist, [], tracelist,[], watchcat, [], watchtag, [],
    tracetag, [], newpage, true, background, "", cardbackground, ""}, flase, newbee, []]),
	case Result of 
        {ok, _} -> 
           ok;
        {error, _} ->
            error
    end.
    
userpage_jsonify(Userinfo) ->
    {{_id,Id,username,Username,_,_,nickname,Nickname,registertime,Registertime,threads,Threads,loves,Loves,stars,Stars,signature,Signature,
    email,Email,avatar,Avatar,_,_,replies,Replies,_,_,_,_,block,Block,role,Role,_,_}} = Userinfo,
        {[{id,list_to_binary(Id)}, {username,list_to_binary(Username)},{nickname,list_to_binary(Nickname)},{registertime,Registertime},
        {threadcount, length(Threads)},{replycount, length(Replies)},{lovecount, length(Loves)},{starcount, length(Stars)},
        {signature,list_to_binary(Signature)},{email,list_to_binary(Email)},{avatar,list_to_binary(Avatar)},
        {block,Block},{role,list_to_binary(Role)}]}.

settings_jsonify(Settings) ->
    {needreply, Needreply, neednotice, Neednotice, needat, Needat, blacklist, Blacklist, replythreadmode, Replythreadmode,
    lovenotice, Lovenotice, watchlist, Watchlist, tracelist, Tracelist, watchcat, Watchcat, watchtag, Watchtag,
    tracetag, Tracetag, newpage, Newpage, background, Background, cardbackground, Cardbackground} = Settings,
    {[{needreply, Needreply}, {neednotice, Neednotice}, {needat, Needat}, {blacklist, lists_to_binary(Blacklist,[])}, {replythreadmode, list_to_binary(Replythreadmode)},
    {lovenotice, Lovenotice}, {watchlist, lists_to_binary(Watchlist,[])}, {tracelist, lists_to_binary(Tracelist,[])}, {watchcat, lists_to_binary(Watchcat,[])}, 
    {watchtag,lists_to_binary(Watchtag,[])}, {tracetag, lists_to_binary(Tracetag,[])}, {newpage, Newpage}, {background, list_to_binary(Background)}, {cardbackground, list_to_binary(Cardbackground)}]}.

activities_jsonify([], Result) ->
	Result1 = lists:reverse(Result),
	Result1;
activities_jsonify([H|T], Result) ->
	{'_id',Id,title,Title,content,Content,read,Read,reply,_,username, Username, 
	category, Category, rtotal, Rtotal, time, Time, loves, 
	Loves, lock, Lock, accesslevel,Accesslevel} = H,
	H1 = {[{title, list_to_binary(Title)},{id, list_to_binary(Id)}, {content, list_to_binary(Content)}, {read, Read}, {reply, Rtotal}, {username, list_to_binary(Username)}, {category,list_to_binary(Category)}, {time, Time}, {loves, Loves}, {lock, list_to_binary(Lock)}, {accesslevel, Accesslevel}]},
	activities_jsonify(T, [H1| Result]).

replies_jsonify([], Result) ->
    Result1 = lists:reverse(Result),
    Result1;
replies_jsonify([H|T], Result) ->
    {'_id', Id, thread, _, content, Content, username, Username, time, Time, threadname, Threadname} = H,
    H1 = {[{id, list_to_binary(Id)}, {content, list_to_binary(Content)}, {username, list_to_binary(Username)},  {time, Time}, {threadname, list_to_binary(Threadname)}]},
    replies_jsonify(T, [H1| Result]).

lists_to_binary([], R) ->
    R;
lists_to_binary([H|T], R) ->
    H1 = list_to_binary(H),
	lists_to_binary(T, [H1|R]).
