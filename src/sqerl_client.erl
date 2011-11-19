%% -*- erlang-indent-level: 4;indent-tabs-mode: nil; fill-column: 92 -*-
%% ex: ts=4 sw=4 et
%% @author Kevin Smith <kevin@opscode.com>
%% @copyright Copyright 2011 Opscode, Inc.
%% @end
%% @doc Abstraction around interacting with SQL databases
-module(sqerl_client).

-behaviour(gen_server).

-include_lib("eunit/include/eunit.hrl").

%% API
-export([start_link/2,
         exec_prepared_select/3,
         exec_prepared_statement/3]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

%% behavior callback
-export([behaviour_info/1]).

-record(state, {cb_mod,
                cb_state}).

%% @hidden
behaviour_info(callbacks) ->
    [{init, 1},
     {exec_prepared_statement, 3},
     {exec_prepared_select, 3}];
behaviour_info(_) ->
    undefined.

%%% A select statement returns a list of tuples, or an error.
%%% The prepared statement to use is named by an atom.
-spec exec_prepared_select(pid(), atom(), [any()]) -> [] | [{any(), any()}] | {error, any()}.
exec_prepared_select(Cn, Name, Args) when is_pid(Cn),
                                                    is_atom(Name) ->
    gen_server:call(Cn, {exec_prepared_select, Name, Args}, infinity).

%%% Unlike a select statement, this just returns an integer or an error.
-spec exec_prepared_statement(pid(), atom(), []) -> integer() | {error, any()}.
exec_prepared_statement(Cn, Name, Args) when is_pid(Cn),
                                             is_atom(Name) ->
    gen_server:call(Cn, {exec_prepared_stmt, Name, Args}, infinity).


start_link(CallbackMod, Config) ->
    gen_server:start_link(?MODULE, [CallbackMod, Config], []).

init([CallbackMod, Config]) ->
    case CallbackMod:init(Config) of
        {ok, CallbackState} ->
            {ok, #state{cb_mod=CallbackMod, cb_state=CallbackState}};
        Error ->
            {stop, Error}
    end.

handle_call({exec_prepared_select, Name, Args}, _From, #state{cb_mod=CBMod,
                                                              cb_state=CBState}=State) ->
    {Result, NewCBState} = CBMod:exec_prepared_select(Name, Args, CBState),
    {reply, Result, State#state{cb_state=NewCBState}};
handle_call({exec_prepared_stmt, Name, Args}, _From, #state{cb_mod=CBMod,
                                                            cb_state=CBState}=State) ->
    {Result, NewCBState} = CBMod:exec_prepared_statement(Name, Args, CBState),
    {reply, Result, State#state{cb_state=NewCBState}};

handle_call(_Request, _From, State) ->
    {reply, ignored, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
