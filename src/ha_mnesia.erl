%%%====================================================================
%%% @author kafuuchino <soranomethods@yahoo.co.jp>
%%% @doc the mnesia manager of hanayuki
%%% @End
%%%====================================================================

-module(ha_mnesia).

-export([init/0, insert_newThread/1, insert_Thread/1, lookup_thread/1]).

-include_lib("stdlib/include/qlc.hrl").

-record(thread, {
	tid,
	title,
    content,
	read,
    reply,
	username,
	category,
	time,
	loves,
    rtotal,
	lock,
	accesslevel,
    lease
	}).

-record(sequence, {name, seq}).
init() ->
	mnesia:start(),
	mnesia:create_table(latestThread, [{type, ordered_set},{attributes, record_info(fields, thread)}]),
    mnesia:create_table(user, [{attributes, record_info(fields, user)}]),
    mnesia:create_table(sequence, [{attributes, record_info(fields, sequence)}, {type, set}, {disc_copies, [node()]}]).

insert_newThread([Title, Content, Read, Reply, Username,
 Category, Rtotal, Time, Loves, Lock, Accesslevel]) ->
    F = fun() ->
        Thread_id = mnesia:dirty_update_counter(sequence, thread, 1),
	    Thread = #thread{tid = ThreadId, 
			title = Title,
            content = Content,
			read = Read,
            reply = Reply,
			username = Username,
			category = Category,
			rtotal = Rtotal, 
			time = Time,
			loves = Loves,
			lock = Lock,
			accesslevel = Accesslevel
	},
    mnesia:write(Thread)
    end,
	mnesia:transaction(F),
    ok.

insert_Thread([Tid, Title, Content, Read, Reply, Username, Category, Rtotal, Time, Loves, 
    Lock, Accesslevel]) ->
        Current_time = os:timestamp(),
        Thread = #thread{tid = Tid,
            title = Title,
            content = Content,
            read = Read,
            reply = Reply,
            username = Username,
            category = Category,
            rtotal = Rtotal,
            time = Time,
            loves = Loves,
            lock = Lock,
            accesslevel = Accesslevel,
            lease = Current_time
        }
        mnesia:dirty_write(Thread),
        ok.

lookup_thread(Tid) ->
	Data = do(qlc:q([{X#thread.title, X#thread.read, X#thread.reply,
		X#thread.uid, X#thread.category, X#thread.time, 
		X#thread.loves, X#thread.lock, X#thread.accesslevel} ||
		X <- mnesia:table(thread), X#thread.tid = Tid])),
	{data, Data}.

do(Q) ->
    F = fun() -> qlc:e(Q) end,
    {atomic, Val} = mnesia:transaction(F),
    Val.
