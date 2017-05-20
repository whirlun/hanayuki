%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc the mnesia manager of hanayuki
%%% @End
%%%====================================================================

-module(ha_mnesia).

-export([init/0, insert_thread/12, lookup_thread/2, insert_user/12]).

-include_lib("stdlib/include/qlc.hrl").

-record(thread, {
	tid,
	title,
	content,
	read,
	reply,
	uid,
	category,
	rtotal,
	time,
	loves,
	lock,
	accesslevel
	}).

-record(user, {
	uid,
	username,
	threads,
	loves,
	signature,
	email,
	avatar,
	friends,
	replies,
	messages,
	settings,
	block,
	role
	}).

init() ->
	mnesia:start(),
	mnesia:create_table(thread, [{type, ordered_set},{attributes, record_info(fields, thread)}]),
	mnesia:create_table(user, [{attributes, record_info(fields, user)}]).

insert_thread(Tid, Title, Content, Read, Reply, Uid,
 Category, Rtotal, Time, Loves, Lock, Accesslevel) ->
	Thread = #thread{tid = Tid, 
			title = Title,
			content = Content,
			read = Read,
			reply = Reply,
			uid = Uid,
			category = Category,
			rtotal = Rtotal, 
			time = Time,
			loves = Loves,
			lock = Lock,
			accesslevel = Accesslevel
	},
	mnesia:dirty_write(Thread).

lookup_thread(Index, Offset) ->
	Data = do(qlc:q([{X#thread.title, X#thread.read, X#thread.reply,
		X#thread.uid, X#thread.category, X#thread.time, 
		X#thread.loves, X#thread.lock, X#thread.accesslevel} ||
		X <- mnesia:table(thread), Index < X#thread.tid,X#thread.tid < Index+Offset])),
	{data, Data}.


insert_user(Uid, Username,Threads, Loves, Signature, Email, Avatar,
 Friends, Repiles, Messages, Block, Role) ->
	User = #user{uid = Uid,
			username = Username,
			threads = Threads,
			loves = Loves,
			signature = Signature,
			email = Email,
			avatar = Avatar,
			friends = Friends,
			replies = Repiles,
			messages = Messages,
			block = Block,
			role = Role
	},
	mnesia:dirty_write(User).

do(Q) ->
    F = fun() -> qlc:e(Q) end,
    {atomic, Val} = mnesia:transaction(F),
    Val.

