%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc Index Helper of Hanayuki
%%% @End
%%%====================================================================

-module(ha_user).
-behaviour(gen_server).

%%API
-export ([start_link/0, register/4, login/2]).

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
        {_} -> {{_id,Id,_,_,password,Pass,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}} = Result,
                Pass1 = crypto:hash(sha256, Password),
                case Pass == Pass1 of
                true -> {reply, State#state{data={[{status, verified}, {id, list_to_binary(Id)}]}}, State};
                false -> {reply, State#state{data={[{status, wrongpass}]}}, State}
            end
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
    , email, avatar, friends, replies, messages, settings, block, role], 
    [Username, Pass, Nickname, 1000000*M+S,[], [], "", Email, "default.jpg", [], [], [], {needreply, true, neednotice, true, needat, true, 
    blacklist, [], replythreadmode, trace, lovenotice, true, watchlist, [], tracelist,[], watchcat, [], watchtag, [],
    tracetag, [], newpage, true, background, "transparent.png", cardbackground, "transparent.png"}, flase, newbee]),
	case Result of 
        ok -> 
           ok;
        {error, _} ->
            error
        end.
