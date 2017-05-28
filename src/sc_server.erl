%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc the main module of TCP server
%%% @End
%%%====================================================================

-module(sc_server).
-include_lib("eunit/include/eunit.hrl").
-behaviour(gen_server).

%%API
-export ([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3,  handle_cast/2, handle_info/2, terminate/2, code_change/3]).


-record(state, {lsock}).

%%%====================================================================
%%% API
%%%====================================================================

%%---------------------------------------------------------------------
%% @doc Start the server
%% @spec start_link(LSock:: Sock()) -> {ok, Pid}
%% where 
%% Pid = pid()
%% @end
%%---------------------------------------------------------------------

start_link(LSock) ->
	gen_server:start_link(?MODULE, [LSock], []).

%%%====================================================================
%%% callbacks
%%%====================================================================


init([LSock]) ->
	{ok, #state{lsock = LSock}, 0}.
	

handle_call(Msg, _From, State) ->
	{reply, {ok, Msg}, State}.

handle_cast(stop, State) ->
	{stop, normal, State}.

handle_info({tcp, Socket, RawData}, State) ->
	NewState = do_rpc(Socket, RawData, State),
	{noreply, NewState};
handle_info({tcp_closed, _Socket}, State) ->
	{stop, normal, State};
handle_info(timeout, #state{lsock = LSock} = State) ->
	{ok, _Sock} = gen_tcp:accept(LSock),
	sc_sup:start_child(),
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%%%====================================================================
%%% Internal functions
%%%====================================================================

do_rpc(Socket, RawData, State) ->
        {M, F, A} = split_out_mfa(RawData),
        Result = apply(list_to_atom(binary_to_list(M)), list_to_atom(binary_to_list(F)), args_to_terms(A, [])),
        {ok, {state, Data}} = Result,
        Jsonify = jiffy:encode(Data, [uescape, force_utf8]),
        gen_tcp:send(Socket, io_lib:fwrite("~p~n", [binary_to_list(Jsonify)])),
    State.

split_out_mfa(RawData) ->
	Data = re:replace(RawData, "\r\n$", ""),
    DecodedData = jiffy:decode(Data),
    {[{<<"module">>, M},{<<"function">>, F},{<<"arg">>, A}]} = DecodedData,
    {M, F, A}.

args_to_terms([], Result) ->
	Args = lists:reverse(Result),
	Args;
args_to_terms([H|T], Result) ->
	H1 = arg_to_term(H),
	args_to_terms(T, [H1|Result]).

arg_to_term(H) when is_binary(H) ->
 list_to_atom(binary_to_list(H));
arg_to_term(H) ->
 	H.