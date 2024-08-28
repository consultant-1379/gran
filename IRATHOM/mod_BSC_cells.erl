%% -*- erlang -*-
%%! -smp enable

%%%!------------------------------------------------------------------
%%% mod_BSC_cells -- 
%%%
%%% @Copyright:    Copyright (C) 2010 Ericsson AB.
%%% @Creator:      Kornel Horvath (ekorhor)
%%% @Date Created: 2010-11-18
%%% @Description:  
%%%-------------------------------------------------------------------
-module(mod_BSC_cells).
-mode(compile).

-rcs('$Id: mod_BSC_cells.erl,v 1.1 2011/01/10 17:00:18 ekorhor Exp $').

-compile(export_all).

-define(SupportedUtranAttrs,
        ["RNCID","CID","FDDARFCN","SCRCODE","QQUALMIN","LAC"]).
-define(MaxBscRelationLimit, 16384).


-record(cell, {
    r,                % Cell Reference: key, unique, integer
    s,                % Simulation name
    m,                % MSC name
    b,                % BSC name
    t,                % Cell type
    n,                % Cell name
    i,                % Cell Global Identifier (CGI or UTRANID)
    used     = false, % If it is used in any relation or not
    mod      = false, % If any attribute is modified or not
    attrs    = [],    % Property list of modified cell attributes
    newattrs = []     % Property list of work datas
    }).

-record(halfrel, {
    sx,             % Simulation index
    s,              % Simulation name
    nx,             % NE index
    n,              % NE name
    cx,             % Cell index
    c,              % Cell name
    cr,             % Cell reference
    part_cgi,       % Tail of CGI or UTRANID: [LAC,CID(,RNCID)]
    props   = []    % 
    }).

-record(utranparam, {
    cid,            % Cell identifier
    lac,            % Location Area Code
    rncid,          % RNC identifier
    attrs = []      % Utran cell attributes
    }).


%%=============================================================================
%%  Main entry point of the script
%%=============================================================================

%%
%%
main(["set_utran_rels" | Params=[_|_]]) ->
    main_set_utran_rels(Params);
main([Mode|_]) -> help(Mode);
main(_)        -> help().



%%=============================================================================
%%  Help messages
%%=============================================================================

help() ->
    simple_help("",
        "For more informations about a mode use only the <Mode> parameter\n"
        "without additional <ModeParam> values.",
        [{"","Mode",     1,1,"One of the followings:\n - set_utran_rels"},
         {"","ModeParam",1,x,"Additonlal parameter of the selected mode."}]).

help(Mode="set_utran_rels") ->
    simple_help(Mode,
        "Set utran relations between internal GSM and external UTRAN cells and set the\n"
        "cell identifier values. The relations are described in <ExpectedRelsFile>\n"
        "file.\n"
        "\n"
        "The GsmSimIdx indices are mapped with <SimName> simulation names.\n"
        "The GsmCellIdx indices is used as CID in the cell identifier of internal GSM\n"
        "cells. The LAC is set to the uniq index of BSC node of the intranel GSM cell.\n"
        "\n"
        "The UtranSimIdx is used as RNCID and UtranCellIdx is used as CID in the cell\n"
        "identifier of external UTRAN cells. The LAC is fetched from the\n"
        "<UtranParams> file.\n"
        "\n"
        "The relations with mapped simulation names, intrnal GSM cells, external UTRAN\n"
        "cell and updated cell identifiers will be saved into various log files in the\n"
        "<OutputDir>/<SimulationName> directory.\n"
        "\n"
        "The result MML scripts will be saved into the same directory. These script \n"
        "contain the commands to apply the cahanges in simulations. Number of scripts\n"
        "will be generated for every BSC node. To merge these MML files into one in the\n"
        "right order use the merge_scripts.sh script.\n"
        "\n",
        [{"expectedrels","ExpectedRelsFile",1,1, get_expresl_help_str()},
         {"simnames",    "SimName",         1,x, "simulation name"},
         {"utranparams", "UtranParamsFile", 1,1, get_utranparams_help_str()},
         {"cells",       "BSCCellsFile",    1,x, get_bsccellpath_help_str()},
         {"outputdir",   "OutputDir",       1,1, "output directory. Defult: current directory"}]);
help(_) ->
    help().


get_expresl_help_str() ->
    "The relations between internal GSM and external UTRAN cells. This is a CSV\n"
    "file that contains four row:\n"
    " - GsmSimIdx: the index of GSM simulation\n"
    " - GsmCellIdx: the uniq index of internal GSM cell in GSM simulations\n"
    " - UtransimIdx: the index of UTRAN simulation\n"
    " - UtranCellIdx: the uniq index of internal UTRAN cell in UTRAN simulations".
get_bsccellpath_help_str() ->
    "The CSV file of orignal list of cells internal GSM, external GSM and\n"
    "external UTRAN cells defined in BSC NEs. The fields are the followings:\n"
    " - sim: the name of the simulation\n"
    " - bsc: the name of the BSC NE\n"
    " - celltype: the type os the cell defined in the BSC. It can be:\n"
    "    INT: internal GSM cell, managed by this BSC\n"
    "    EXT: external GSM cell, managfed by an other BSC\n"
    "    UTRAN: external UTRAN cell, managed by an RNC or RBS\n"
    " - CELL: the name of the cell\n"
    " - CGI or UTRANID: the PLNM, location are and cell identifier values of the GSM cell\n"
    "   and the RNC identifier too for UTEN cells. The format is:\n"
    "    MCC-MNC-LAC-CID: for internal and external GSM cells\n"
    "    MCC-MNC-LAC-CID-RNCID: for external UTRAN cells\n"
    " - any other legal attribute for a cell.".
get_bsccellpath2_help_str() ->
    "The CSV file of updated list of cells internal GSM, external GSM and\n"
    "external UTRAN cells defined in BSC NEs. The fields ar the followings:\n"
    "SimName, BSCName, CellType, CellName, CellId, NewCellId.".
get_filter_help_str() ->
    "This CSV file contains cell defineitions like other input CSV cell files\n"
    "but any field can be \"all\". The fields ar the followings:\n"
    "SimName, BSCName, CellType, CellName, CellId.".
get_inpath_help_str(CellType) ->
    "This CSV file contains the "++CellType++" cell parameters in the following\n"
    "order: SimName, BSCName, CellType, CellName, CellId.".
get_inpath2_help_str(CellType) ->
    "This CSV file contains the updated "++CellType++" cell parameters in\n"
    "the following order: SimName, BSCName, CellType, CellName, CellId, NewCellId".
get_outpath_help_str(CellType) ->
    "The output CSV file for "++CellType++" cells.\n"
    "Same as the input file for "++CellType++" but it has one more CellId colum\n"
    "which contains the updated cell identifier values.".
get_utranparams_help_str() ->
    "This CSV file contains the CID, LAC values and any other attributes for\n"
    "UTRAN cells. The values must be in \"Key=Value\" format. The allowed\n"
    "attributes are the followings:\n"
    " - CID: 0-65535\n"
    " - LAC: 1-65535\n"
    " - RNCID: 0-4095\n"
    " - FDDARFCN: 0-16383\n"
    " - SCRCODE: 0-511\n"
    " - MRSL: 0-49\n"
    "To generate this CSV file from logs from WRAN side use the\n"
    "createUtranCells_INFO.sh script.".


simple_help(Mode, Desc, Params) ->
    Name     = escript:script_name(),
    Ext      = filename:extension(Name),
    BaseName = filename:basename(Name, Ext),
    Usage =
        [ begin
              Prefix = case OptKey of "" -> ""; _  -> "-"++OptKey++" " end,
              case {Min,Max} of
                  {0,1} -> "["++Prefix++"<"++PName++">]";
                  {0,_} -> "["++Prefix++"<"++PName++"> ...]";
                  {1,1} -> Prefix++"<"++PName++">";
                  {1,_} -> Prefix++"<"++PName++"> [<"++PName++"> ...]"
              end
          end || {OptKey,PName,Min,Max,_Desc}<-Params],
    HelpStr =
        "Usage: "++BaseName++" "++Mode++" "++string:join(Usage," ")++"\n"
        "\n"
        "where\n" ++
        [" "++PName++"\n"++
         "    "++
         re:replace(lists:flatten(PDesc),"\n","\n    ",[global,{return,list}])++
         "\n"
         || {_OptKey,PName,_Min,_Max,PDesc}<-Params] ++
        "\n"
        "DESCRIPTION:\n" ++
        " "++
        re:replace(lists:flatten(Desc),"\n","\n ",[global,{return,list}])++"\n",
    io:format(HelpStr, []).



%%=============================================================================
%%  Set utran relations and update cell identifiers
%%=============================================================================

%%!-------------------------------------------------------------------
%% main_set_utran_rels -- Set utran relations and update cell identifiers
%% 
%% main_set_utran_rels(Params) -> void()
%%   Params = [string()]
%%   
%% Set utran relations and update cell identifiers
%%--------------------------------------------------------------------
main_set_utran_rels(Params) ->
    % Read files
    io:format("Read files:\n", []),
    {ExpSimNames, {BSCCells0,_BSCCellPathRefs0,_NumCells0},
     {ExpRels,_NumExpRels}, {UtranParams, NumUtranParams}, OutDir} =
        try
            read_files(Params)
        catch
            error:Error ->
                Trace = erlang:get_stacktrace(),
                io:format("ERROR: ~p\nStack trace = ~p\n", [Error, Trace]);
              throw:Exception ->
                Trace = erlang:get_stacktrace(),
                io:format("EXCEPTION: ~p\nStack trace = ~p\n",
                          [Exception, Trace])
        end,

    io:format("Store CID, LAC, RNCID and other attribute values of UTRAN cells "
              "... ", []),
    UtranParams_ETS = create_utran_table(UtranParams, ExpRels),
    io:format("~b cells from ~b\n",
              [ets:info(UtranParams_ETS,size),NumUtranParams]),

    io:format("Filter sort cells:\n", []),
    {GSXs, GSXGSs, GS_GBs, Cells_ETS, SimBsc_Refs_ETS, CellId_Ref_ETS} = 
        filter_sort_cells(ExpRels, ExpSimNames, BSCCells0),

    io:format("Group relations:\n", []),
    SimBsc_Rels = group_gsm_rels(GSXs, GSXGSs, GS_GBs, ExpRels, SimBsc_Refs_ETS,
                                 UtranParams_ETS),

    io:format("Map relations and update cells ...\n", []),
    SimBsc_Rels2 = map_rels_update_cells(SimBsc_Rels, Cells_ETS,
                                         SimBsc_Refs_ETS, CellId_Ref_ETS,
                                         UtranParams_ETS),

    gen_mml(Cells_ETS, SimBsc_Refs_ETS, SimBsc_Rels2, OutDir),

    ok.



%%-----------------------------------------------------------------------------
%%  Read input files
%%-----------------------------------------------------------------------------


%%!-------------------------------------------------------------------
%% read_files -- 
%% 
%% read_files() -> Result
%%   
%% 
%%--------------------------------------------------------------------
read_files(Params) ->
    % Get command line options
    Options           = get_options(Params, "", []),
    BSCCellPathes     = [File    || {"cells",File}<-Options],
    [ExpectedRelPath] = [File    || {"expectedrels",File}<-Options],
    [UtranParamsPath] = [File    || {"utranparams",File}<-Options],
    SimNames0         = [SimName || {"simnames",SimName}<-Options],
    [OutDir0]         = [Dir     || {"outputdir", Dir}<-Options],

    % Check
    OutDir = check_outdir(OutDir0),

    % Read BSC cells files
    io:format("  Read BSC cells ... ", []),
    {BSCCells, BSCCellPathRefs, NumCells} = load_index_bsc_cells(BSCCellPathes),
    io:format("~b cells\n", [NumCells]),

    % Read expected relations
    io:format("  Read expected relations ... ", []),
    ExpRels0   = read_csv(ExpectedRelPath),
    ExpRels1   = [{#halfrel{sx=list_to_integer(GSX),cx=list_to_integer(GCX)},
                   #halfrel{sx=list_to_integer(USX),cx=list_to_integer(UCX)}}
                  || {GSX,GCX,USX,UCX}<-ExpRels0],
    ExpRels    = lists:sort(ExpRels1),
    NumExpRels = length(ExpRels),
    io:format("~b relatoins\n", [NumExpRels]),

    % Read UTRAN cell attributes in expected realtions
    io:format("  Read UTRAN cell attributes in expected realtions ... ", []),
    UtranParams    = load_utran_params(UtranParamsPath),
    NumUtranParams = length(UtranParams),
    io:format("~b cells\n", [NumUtranParams]),


    % Return lists
    {SimNames0, {BSCCells, BSCCellPathRefs, NumCells}, {ExpRels, NumExpRels},
     {UtranParams, NumUtranParams}, OutDir}.


% Get command line options
get_options([], _Opt, Options) ->
    lists:reverse(Options);
get_options([[$-|Opt]|Params], _Opt, Options) ->
    get_options(Params, Opt, Options);
get_options([Param|Params], Opt, Options) ->
    get_options(Params, Opt, [{Opt,Param}|Options]).

% Check output directory is exists and writable
check_outdir(OutDir) ->
    case {filelib:is_dir(OutDir),
          filelib:ensure_dir(filename:join([OutDir,"sim","bsc","x.txt"]))} of
        {true, ok}  ->
            filename:absname(OutDir);
        {false, _} ->
            Msg1 = lists:flatten(io_lib:format("Directory is not exists: ~s",
                                               [OutDir])),
            throw({error, Msg1});
        {true, {error, Reason}} ->
            Msg2 = lists:flatten(io_lib:format("Has no write permission in "
                                               "directory (~p): ~s",
                                               [Reason, OutDir])),
            throw({error, Msg2})
    end.

% Add a serial number for every BSC cell as uniq identifier
load_index_bsc_cells(BSCCellPathes) ->
    index_bsc_cells([read_csv(FN)||FN<-BSCCellPathes],BSCCellPathes,1,[],[]).

index_bsc_cells([], [], Idx, Refs, FlatCells) ->
    {lists:reverse(FlatCells), lists:reverse(Refs), Idx-1};
index_bsc_cells([Cells|BSCCellLists], [BSCCellPath|BSCCellPathes], Idx,
                RefLists, FlatCells) ->
    {Idx2, FlatCells2} = index_bsc_cells_(Cells, Idx, FlatCells),
    index_bsc_cells(BSCCellLists, BSCCellPathes, Idx2,
                    [{BSCCellPath, lists:seq(Idx,Idx2-1)}|RefLists],
                    FlatCells2).

index_bsc_cells_([], Idx, FlatCells) ->
    {Idx, FlatCells};
% index_bsc_cells_([{S,B,T,N,I}|Cells], Idx, FlatCells) ->
%     %     index_bsc_cells_(Cells, Idx+1, [{Idx,S,B,T,N,I,no}|FlatCells]).
%     index_bsc_cells_(Cells,Idx+1, [#cell{r=Idx,s=S,b=B,t=T,n=N,i=I}|FlatCells]).
index_bsc_cells_([Rec|Cells], Idx, FlatCells) ->
    %     index_bsc_cells_(Cells, Idx+1, [{Idx,S,B,T,N,I,no}|FlatCells]).
    List0 =
        [list_to_tuple(case [string:strip(Str)||Str<-string:tokens(Attr,"=")] of
                            [Key]     -> [Key,""];
                            KeyValue  -> KeyValue
                       end)
         || Attr<-tuple_to_list(Rec)],
    {value, {"sim",      S}, List1} = lists:keytake("sim",      1, List0),
    {value, {"msc",      M}, List2} = lists:keytake("msc",      1, List1),
    {value, {"bsc",      B}, List3} = lists:keytake("bsc",      1, List2),
    {value, {"celltype", T}, List4} = lists:keytake("celltype", 1, List3),
    {value, {"CELL",     N}, List5} = lists:keytake("CELL",     1, List4),
    {I,List6} =
        case T of
            "UTRAN" ->
                {value,{"UTRANID",UI},UList6}=lists:keytake("UTRANID",1,List5),
                {UI,UList6};
            _ ->
                {value,{"CGI",GI},GList6} = lists:keytake("CGI",1,List5),
                {GI,GList6}
        end,
    index_bsc_cells_(Cells,Idx+1,
                     [#cell{r=Idx,s=S,m=M,b=B,t=T,n=N,i=I,attrs=List6} |
                      FlatCells]).


% Load UTAN cell parameters
load_utran_params(UtranParamsPath) ->
    UtranParams0 = read_csv(UtranParamsPath),
    [ begin
        Attrs0 = [begin
                    [K, V] = string:tokens(Field, "="),
                    {K, V}
                  end
                  || Field<-tuple_to_list(Rec)],
        Attrs1 = [Attr || Attr={K,_}<-Attrs0,
                  lists:member(K, ?SupportedUtranAttrs)],
        {value, {"CID",  CID},   Attrs2} = lists:keytake("CID",  1,Attrs1),
        {value, {"LAC",  LAC},   Attrs3} = lists:keytake("LAC",  1,Attrs2),
        {value, {"RNCID",RNCID}, Attrs4} = lists:keytake("RNCID",1,Attrs3),
        % Convert qQualMin of UTRAN cell in RNC to MRSL of UTRANCELL in BSC
        {value, {"QQUALMIN",QQualMin}, Attrs5} =
            lists:keytake("QQUALMIN",1,Attrs4),
        MRSL = erlang:min(0, erlang:max(49,
                   floor((list_to_integer(QQualMin)+24)*2) )),
        Attrs6 = lists:keystore("MRSL", 1, Attrs5,
                                {"MRSL",integer_to_list(MRSL)}),
        % Create UTRAN cell parameters record
        #utranparam{cid=list_to_integer(CID), lac=list_to_integer(LAC),
                    rncid=list_to_integer(RNCID), attrs=Attrs6}
    end
    || Rec<-UtranParams0].


%%!-------------------------------------------------------------------
%% floor -- Calculate the floor of a number
%% 
%% floor(N1) -> N2
%%   N1 = float() | integer()
%%   N2 = integer()
%%--------------------------------------------------------------------
floor(N) ->
    case float(round(N)) == N of
        true ->
            round(N);
        false ->
            round(N - 0.5)
    end.


%%-----------------------------------------------------------------------------
%%  Filter simulations and cells
%%-----------------------------------------------------------------------------

%
%
filter_sort_cells(ExpRels, ExpSimNames, BSCCells) ->
    % Get simulation indices
    GSXs   = lists:usort([GSX || {#halfrel{sx=GSX}, #halfrel{}}<-ExpRels]),
    MinGSX = lists:min(GSXs),
    MaxGSX = lists:max(GSXs),
    if
        length(ExpSimNames)<MaxGSX-MinGSX+1 ->
            Msg = lists:flatten(io_lib:format(
                    "There are less simulations name given in command line "
                    "(~b) than the expected realtion file contains (~b)",
                    [length(ExpSimNames), MaxGSX-MinGSX+1])),
            throw({error, Msg});
        true ->
            ok
    end,
    % Map simulation indices to simulation names
    GSXGSs = [{GSX,lists:nth(GSX-MinGSX+1, ExpSimNames)} || GSX<-GSXs],
    GSs    = [GS || {_GSX,GS}<-GSXGSs],
    % Used simulations
    io:format("  Simulations in relations:\n", []),
    [io:format("    ~b. ~s\n", [GSX,GS]) || {GSX,GS}<-GSXGSs],

    % Check common simulations between simulations and expectations
    % SimNames contains names in original order
    Ss = lists:usort([S || #cell{s=S}<-BSCCells]),
    case GSs--Ss of
        [] ->
            ok;
        MissedSs ->
            Msg2 = lists:flatten(io_lib:format(
                    "The lists of BSC cells are missing for simulations: ~p",
                    [MissedSs])),
            throw({error, Msg2})
    end,

    % Keep cells only from used simulations
    io:format("  Keep BSC cells only from used simulations ... ", []),
    BSCCells1 = [Cell || Cell=#cell{s=S}<-BSCCells, lists:member(S,GSs)],
    io:format("~b cells from ~b\n", [length(BSCCells1), length(BSCCells)]),

    % List BSC names for smiulations
    GS_GBs = [{S, lists:usort([B||#cell{s=S1,b=B}<-BSCCells1, S1=:=S])}
              || S<-GSs],

    % Store cell definitions
    io:format("  Store BSC cells ...\n", []),
    {Cells_ETS,SimBSC_Refs_ETS,CellId_Ref_ETS} = store_cells(BSCCells1,GS_GBs),

    {GSXs, GSXGSs, GS_GBs, Cells_ETS, SimBSC_Refs_ETS, CellId_Ref_ETS}.



%%-----------------------------------------------------------------------------
%%  Group relation by simulations and BSC NEs
%%-----------------------------------------------------------------------------

%
%
group_gsm_rels(GSXs, GSXGSs, GS_GBs, ExpRels, SimBsc_Refs_ETS,
               UtranParams_ETS) ->
    % [{ GSX,GS, [{GB,NumIG,NumEG,NumEU}] }]
    io:format("  Partition relations by simulations ...\n", []),
    SimBscNumCells = get_num_cells(GSXs, GSXGSs, GS_GBs, SimBsc_Refs_ETS),
    % [{ GSX, [{G,[U]}] }]
    ExpSimRels = get_GSM_rels_per_sim(ExpRels),
    % [{ GSX,GS, [{GBX,GB, [{G,[U]}] }] }]
    io:format("  Partition relations by BSC nodes ...\n", []),
    SimBsc_Cells =
        [begin
             % { GSX, [{G,[U]}] }
             {GSX, G_Us}  = lists:keyfind(GSX, 1, ExpSimRels),
             % [{B, [{G,[U]}] }]
             GB_Rels = group_gsm_rels_per_bsc(G_Us, GBNumCells),
             case GB_Rels of
                 List when is_list(List) -> ok;
                 {not_enough_cells, GsmRels} ->
                     Gs = lists:usort([G||{G,_Us}<-GsmRels]),
                     Us = lists:usort([U||{_G,Us}<-GsmRels, U<-Us]),
                     Msg = lists:flatten(io_lib:format(
                            "There are ~b intranal GSM and ~b external UTRAN "
                            "cell in the expected relations without any BSC NE "
                            "with enough cell definition.",
                            [length(Gs), length(Us)])),
                     throw({error, Msg})
             end,
             {GSX,GS, GB_Rels}
         end
         || {GSX,GS, GBNumCells}<-SimBscNumCells],
    % { NumBSC,   [{ GSX,GS, [{GBX,GB, [{G,[U]}] }] }]   }
    io:format("  Index BSC nodes ...\n", []),
    {_NumBsc, SimBscx_Cells} = index_bscs(SimBsc_Cells, 1, []),
    io:format("  Update cell identifiers ...\n", []),
    update_rels(SimBscx_Cells, UtranParams_ETS).


% [{G=#halfrel{}, [U=#halfrel{}]}]
% [{G, [U]}]
get_GSM_rels(ExpRels) ->
    get_GSM_rels_(lists:usort(ExpRels), will_be_removed, [[will_be_removeb]]).

get_GSM_rels_([], G0, [Us|GroupRels]) ->
    tl(lists:reverse([{G0,lists:reverse(Us)}|GroupRels]));
get_GSM_rels_([{G,U}|Rels], G, [Us|GroupRels]) ->
    get_GSM_rels_(Rels, G, [[U|Us]|GroupRels]);
get_GSM_rels_([{G,U}|Rels], G0, [Us|GroupRels]) ->
    get_GSM_rels_(Rels, G, [[U],{G0,lists:reverse(Us)}|GroupRels]).


% [{ GSX, [{G=#halfrel{}, [U=#halfrel{}]}] }]
% [{ GSX, [{G,[U]}] }]
get_GSM_rels_per_sim(ExpRels) ->
    get_GSM_rels_per_sim_(get_GSM_rels(ExpRels), will_be_removed,
                          [[will_be_removeb]]).

get_GSM_rels_per_sim_([], GSX0, [GSXRels|SimRels]) ->
    tl(lists:reverse([{GSX0,lists:reverse(GSXRels)}|SimRels]));
get_GSM_rels_per_sim_([GRels={#halfrel{sx=GSX}, _Us}|GroupRels], GSX,
                      [GSXRels|SimRels]) ->
    get_GSM_rels_per_sim_(GroupRels, GSX, [[GRels|GSXRels]|SimRels]);
get_GSM_rels_per_sim_([GRels={#halfrel{sx=GSX}, _Us}|GroupRels], GSX0,
                      [GSXRels|SimRels]) ->
    get_GSM_rels_per_sim_(GroupRels, GSX,
                          [[GRels],{GSX0,lists:reverse(GSXRels)}|SimRels]).


% [{ GSX,GS, [{GB,NumIG,NumEG,NumEU}] }]
%
get_num_cells(GSXs, GSXGSs, GS_GBs, SimBsc_Refs_ETS) ->
    [begin
         {GSX, GS} = lists:keyfind(GSX, 1, GSXGSs),
         {GS, GBs} = lists:keyfind(GS, 1, GS_GBs),
         NumGBsCells =
             [begin
                  IGRefs = get_sim_bsc_refs(SimBsc_Refs_ETS, GS,GB,"INT"),
                  EGRefs = get_sim_bsc_refs(SimBsc_Refs_ETS, GS,GB,"EXT"),
                  EURefs = get_sim_bsc_refs(SimBsc_Refs_ETS, GS,GB,"UTRAN"),
                  {GB,length(IGRefs),length(EGRefs),length(EURefs)}
              end                    
              || GB<-GBs],
         {GSX,GS,NumGBsCells}
     end
     || GSX<-GSXs].

get_sim_bsc_refs(SimBsc_Refs_ETS, S, B, T) ->
    case ets:lookup(SimBsc_Refs_ETS, {S,B,T}) of
        []       -> [];
        [{_,Rs}] -> Rs
    end.


% [{B, [{G,[U]}] }]
%
group_gsm_rels_per_bsc(GsmRels, BscNumCells) ->
    BNumCells = [{B,NumIGs,NumEUs,[],[],[]} ||
                    {B,NumIGs,_NumEGs,NumEUs}<-BscNumCells],
    group_gsm_rels_per_bsc_(GsmRels, BNumCells, []).

group_gsm_rels_per_bsc_([], _NumCells=[], BRels) ->
    lists:reverse(BRels);
group_gsm_rels_per_bsc_([],[{_B,_NumIG,_NumEU,_B_Gs,_B_Us,_Rels=[]}|_BNumCells],
                        BRels) ->
    lists:reverse(BRels);
group_gsm_rels_per_bsc_([], [{B,_NumIG,_NumEU,_B_Gs,_B_Us,Rels}|_BNumCells],
                        BRels) ->
    lists:reverse([{B,lists:reverse(Rels)}|BRels]);
group_gsm_rels_per_bsc_(GsmRels=[_|_], _NumCells=[], _BRels) ->
    {not_enough_cells, GsmRels};
group_gsm_rels_per_bsc_(GsmRels=[Rel={G,Us}|Gs_Rels],
                        [{B,NumIG,NumEU,B_Gs,B_Us,Rels}|BNumCells], BRels) ->
    B_Gs2 = union([G],B_Gs),
    B_Us2 = union(Us,B_Us),
    % Check if there enough cells in the curernt BSC
    case NumIG<length(B_Gs2) orelse NumEU<length(B_Us2) of
        false -> % Add GRels to the current BSC
            group_gsm_rels_per_bsc_(Gs_Rels, 
                [{B,NumIG,NumEU,B_Gs2,B_Us2,[Rel|Rels]}|BNumCells], BRels);
        true -> % Create new empty list of cells for the next BSC and try that
            group_gsm_rels_per_bsc_(GsmRels, BNumCells,
                [{B,lists:reverse(Rels)}|BRels])
    end.

union(List1, List2) -> lists:usort(List1++List2).

% [{ GSX,GS, [{GBX,GB, [{G,[U]}] }] }]
%
index_bscs([], GBX, SimBscx_Rels) ->
    {GBX-1, lists:reverse(SimBscx_Rels)};
index_bscs([{GSX,GS,GB_Rels}|SimBsc_Rels], GBX, SimBscx_Rels) ->
    {GBX2, GBX_Rels} = index_bscs_(GB_Rels, GBX, []),
    index_bscs(SimBsc_Rels, GBX2, [{GSX,GS,GBX_Rels}|SimBscx_Rels]).

index_bscs_([], GBX, GBX_Rels) -> 
    {GBX, lists:reverse(GBX_Rels)};
index_bscs_([{GB,Rels}|GB_Rels], GBX, GBX_Rels) -> 
    index_bscs_(GB_Rels, GBX+1, [{GBX,GB,Rels}|GBX_Rels]).


% [{ GSX,GS, [{GBX,GB, [{G,[U]}] }] }]
%
update_rels(SimBscx_Cells, UtranParams_ETS) ->
    [{GSX,GS,
      [{GBX,GB,
        [begin
             G2 = update_gsm_halfrel(G, GSX,GS,GBX,GB),
             {G2,
              [update_utran_halfrel(U,G2, GSX,GS,GBX,GB, UtranParams_ETS)
               ||U<-Us]}
         end
         ||{G,Us}<-Rels]
       }
       || {GBX,GB, Rels}<-GB_Rels]
     } 
     || {GSX,GS, GB_Rels}<-SimBscx_Cells].

update_gsm_halfrel(G=#halfrel{sx=GSX, cx=GCX}, GSX,GS,GBX,GB) ->
    G#halfrel{s=GS, nx=GBX, n=GB, part_cgi=[GBX,GCX]}.

update_utran_halfrel(U=#halfrel{cx=UCX}, #halfrel{sx=GSX},
                     GSX,GS,GBX,GB, UtranParams_ETS) ->
    [#utranparam{cid=Cid,lac=Lac,rncid=RncId}] =
        ets:lookup(UtranParams_ETS, UCX),
    U#halfrel{s=GS, nx=GBX, n=GB, part_cgi=[Lac,Cid,RncId]}.




%%-----------------------------------------------------------------------------
%%  Map realtions to cells and update cells
%%-----------------------------------------------------------------------------

%
%
map_rels_update_cells(SimBsc_Rels, Cells_ETS, SimBsc_Refs_ETS, CellId_Ref_ETS,
        UtranParams_ETS) ->
    lists:map(
        fun({GSX,GS,GB_Rels}) ->
            {GSX, GS,
            lists:map(
                fun({GBX,GB, Rels}) ->
                    Gs = [G||{G,_Us}<-Rels],
                    Us = lists:usort(lists:flatten([Us1||{_G,Us1}<-Rels])),
                    [{_,IGRefs}] = ets:lookup(SimBsc_Refs_ETS, {GS,GB,"INT"}),
                    [{_,EURefs}] = ets:lookup(SimBsc_Refs_ETS, {GS,GB,"UTRAN"}),
                    MappedGs = get_halfrel_map(Gs, IGRefs, Cells_ETS),
                    MappedUs = get_halfrel_map(Us, EURefs, Cells_ETS),
                    [update_gsm_cell(MappedG,Cells_ETS,CellId_Ref_ETS)
                     || MappedG<-MappedGs],
                    [update_utran_cell(MappedU,Cells_ETS,CellId_Ref_ETS,
                                       UtranParams_ETS)
                     || MappedU<-MappedUs],
                    MappedRels = map_rels(Rels, MappedGs, MappedUs),
                    {GBX,GB, MappedRels}
                end,
                GB_Rels)}
        end,
        SimBsc_Rels).

%
get_halfrel_map(HalfRels, CellRefs, Cells_ETS) ->
    Cells = lists:flatten([ets:lookup(Cells_ETS,R) || R<-CellRefs]),
    GRefNamePartCGIs =
        [{R,N,[list_to_integer(S)||S<-lists:nthtail(2,string:tokens(I,"-"))]}
         || #cell{r=R, n=N, i=I}<-Cells],
    {MappedHRs0,RemHRs,RemRefNamePartCGIs} =
        list_partzip(HalfRels,#halfrel.part_cgi, GRefNamePartCGIs,3),
    NumRemHRs  = length(RemHRs),
    MappedHRs1 = MappedHRs0 ++
        lists:zip(RemHRs, lists:sublist(RemRefNamePartCGIs,NumRemHRs)),
    [{HR,R,N,PartCGI} || {HR,{R,N,PartCGI}}<-MappedHRs1].


list_partzip(List1, MatchIdx1, List2, MatchIdx2) ->
    list_partzip_(lists:keysort(MatchIdx1, List1),
                  lists:keysort(MatchIdx2, List2), MatchIdx1, MatchIdx2,
                  [], [], []).

list_partzip_([], Ys, _Idx1, _Idx2, BothXY, OnlyX, OnlyY) ->
    {lists:reverse(BothXY), lists:reverse(OnlyX), lists:reverse(OnlyY,Ys)};
list_partzip_(Xs, [], _Idx1, _Idx2, BothXY, OnlyX, OnlyY) ->
    {lists:reverse(BothXY), lists:reverse(OnlyX,Xs), lists:reverse(OnlyY)};
list_partzip_([X|Xs], [Y|Ys], Idx1, Idx2, BothXY, OnlyX, OnlyY) ->
    XE = element(Idx1,X),
    YE = element(Idx2,Y),
    if
        XE=:=YE -> list_partzip_(Xs,Ys, Idx1,Idx2, [{X,Y}|BothXY],OnlyX,OnlyY);
        XE<YE   -> list_partzip_(Xs,[Y|Ys], Idx1,Idx2, BothXY,[X|OnlyX],OnlyY);
        true    -> list_partzip_([X|Xs],Ys, Idx1,Idx2, BothXY,OnlyX,[Y|OnlyY])
    end.


map_rels(Rels, MappedGs, MappedUs) ->
    [{map_halfrel(G,MappedGs), [map_halfrel(U,MappedUs)||U<-Us]}
     || {G,Us}<-Rels].

map_halfrel(HR=#halfrel{}, MappedHRs) ->
    {HR, R, N, _ParCGI} = lists:keyfind(HR, 1, MappedHRs),
    HR#halfrel{c=N, cr=R}.


update_gsm_cell({#halfrel{part_cgi=[Lac,Cid]}, R,_N,_PartCgi}, Cells_ETS,
        CellId_Ref_ETS) ->
    % Calc new CGI
    [#cell{i=CGI}] = ets:lookup(Cells_ETS, R),
    [MCC,MNC,_LAC,_CID] = string:tokens(CGI,"-"),
    CGI2 = lists:flatten(io_lib:format("~s-~s-~b-~b",[MCC,MNC,Lac,Cid])),
    % Set all GSM cell with same CGI
    [{CGI, Refs}] = ets:lookup(CellId_Ref_ETS, CGI),
    lists:foreach(
        fun(Ref) ->
            [GCell=#cell{attrs=Attrs,newattrs=NewAttrs}] =
                ets:lookup(Cells_ETS, Ref),
            % Add gsm attributes to the cell that have to change by expected gsm
            % attributes
            ExpAttrs2 =
                if
                    CGI=:=CGI2 ->
                        [];
                    true -> % Modify only if CGI is changed
                        [{"CGI",CGI2}]
                end,
            % Set only attributes that are not set already or not the same as
            % original
            NewAttrs2 = NewAttrs++((ExpAttrs2--NewAttrs)--Attrs),
            % Update the utran cell if anything was changed
            if
                NewAttrs2=:=NewAttrs ->
                    ets:insert(Cells_ETS, GCell#cell{used=true});
                true ->
                    ets:insert(Cells_ETS, GCell#cell{used=true, mod=true,
                                                     newattrs=NewAttrs2})
            end
        end,
        Refs).

update_utran_cell({#halfrel{part_cgi=[Lac,Cid,RncId]}, R,_N,_PartCgi},
        Cells_ETS, _CellId_Ref_ETS, UtranParams_ETS) ->
    % Calc new UTRANID
    [#cell{i=UTRANID}] = ets:lookup(Cells_ETS, R),
    [MCC,MNC,_LAC,_CID,_RNCID] = string:tokens(UTRANID,"-"),
    UTRANID2 = lists:flatten(io_lib:format("~s-~s-~b-~b-~b",
                                           [MCC,MNC,Lac,Cid,RncId])),
    % Get additional expected attributes
    [#utranparam{attrs=ExpAttrs}] = ets:lookup(UtranParams_ETS, Cid),
%%     % Set all UTRAN cell with same UTRANID
%%     [{UTRANID, Refs}] = ets:lookup(CellId_Ref_ETS, UTRANID),
    lists:foreach(
        fun(Ref) ->
            [UCell=#cell{n=_N, attrs=Attrs,newattrs=NewAttrs}] =
                ets:lookup(Cells_ETS, Ref),
            % Add utran attributes to the cell that have to change by expected
            % utran attributes
            ExpAttrs2 =
                if
                    UTRANID=:=UTRANID2 ->
                        ExpAttrs;
                    true ->  % Modify only if UTRANID is changed
                        lists:keystore("UTRANID", 1, ExpAttrs,
                                       {"UTRANID",UTRANID2})
                end,
            % Leave UTRAN cell names unchanged
            %NewName = lists:flatten(io_lib:format("~2..0b~5..0b", [RncId,Cid])),
            %ExpAttrs3 =
            %    if  N=:=NewName ->
            %            ExpAttrs2;
            %        true ->
            %            lists:keystore("NEWNAME", 1, ExpAttrs2,
            %                           {"NEWNAME", NewName})
            %    end,
            % Set only attributes that are not set already or not the same as
            % original
            NewAttrs2 = NewAttrs++((ExpAttrs2--NewAttrs)--Attrs),
            % Update the utran cell if anything was changed
            if
                NewAttrs2=:=NewAttrs ->
                    ets:insert(Cells_ETS, UCell#cell{used=true});
                true ->
                    ets:insert(Cells_ETS, UCell#cell{used=true, mod=true,
                                                     newattrs=NewAttrs2})
            end
        end,
        [R]).
%%         Refs).



%%-----------------------------------------------------------------------------
%%  Generate MML scripts
%%-----------------------------------------------------------------------------

gen_mml(Cells_ETS, SimBsc_Refs_ETS, SimBsc_Rels, OutDir) ->
    io:format("Generate MML scripts:\n", []),
    lists:foreach(
        fun({_GSX,GS, GB_Rels}) ->
            OutDirS = filename:join(OutDir,GS),
            case filelib:is_dir(OutDirS) of
                true  -> ok;
                false -> file:make_dir(OutDirS)
            end,
            io:format("  Simulation ~s:\n", [GS]),
            lists:foreach(
                fun({_GBX,GB,Rels}) ->
                    io:format("    BSC ~s ...\n", [GB]),
                    gen_updated_cells_mml(GS,GB,Cells_ETS,SimBsc_Refs_ETS,
                                          OutDirS),
                    gen_updated_rels_mml(GS,GB,Rels,Cells_ETS,OutDirS)
                end,
                GB_Rels)
        end,
        SimBsc_Rels).
    

gen_updated_cells_mml(S,B,Cells_ETS,SimBsc_Refs_ETS,OutDir) ->
    gen_updated_cells_mml_(S,B,Cells_ETS,SimBsc_Refs_ETS,OutDir,"INT", false),
    gen_updated_cells_mml_(S,B,Cells_ETS,SimBsc_Refs_ETS,OutDir,"EXT", false),
    gen_updated_cells_mml_(S,B,Cells_ETS,SimBsc_Refs_ETS,OutDir,"UTRAN", true).

gen_updated_cells_mml_(S,B,Cells_ETS,SimBsc_Refs_ETS,OutDir,CellType,
        DeleteNotUsed) ->
    % MML script
    [{_,Refs}] = ets:lookup(SimBsc_Refs_ETS, {S,B,CellType}),
    {M, MscUpdLines, MscDelLines, BscUpdLines, BscDelLines, BSCCells} = 
        get_cells_lines(Refs, Cells_ETS, DeleteNotUsed),
    % Wait for the second (spontanuos) printouts about deleting cells
    BscDelLines1 =
        case BscDelLines of
            [] -> [];
            _  -> lists:flatten(
                    [".asyncmsgwait ensurestartedandreset\n","\n",
                     [[Cmd,".asyncmsgwait waitfor rpr\n"] || Cmd<-BscDelLines],
                     ".asyncmsgwait ensurestopped\n","\n"])
        end,
    DelLines1 = if  []=:=MscDelLines -> [];
                    true -> [".select "++M++"\n"|MscDelLines]
                end ++
                if  []=:=BscDelLines -> [];
                    true -> [".select "++B++"\n"|BscDelLines1]
                end,
    UpdLines1 = if  []=:=BscUpdLines -> [];
                    true -> [".select "++B++"\n"|BscUpdLines]
                end ++
                if  []=:=MscUpdLines -> [];
                    true -> [".select "++M++"\n"|MscUpdLines]
                end,
    MMLDelPath = filename:join(OutDir, B++".cells."++CellType++".delete.mml"),
    MMLUpdPath = filename:join(OutDir, B++".cells."++CellType++".update.mml"),
    BSCCellsPath = filename:join(OutDir, B++".cells."++CellType++".BSCCells"),
    file:write_file(MMLDelPath, list_to_binary(lists:flatten(DelLines1))),
    file:write_file(MMLUpdPath, list_to_binary(lists:flatten(UpdLines1))),
    file:write_file(BSCCellsPath, list_to_binary(lists:flatten(BSCCells))),
    % Dump
    DumpPath  = filename:join(OutDir, B++".cells."++CellType++".dump.erl"),
    DumpLine1 = "% {cell, Cell reference, Sim name, MSC name, BSC name, "
                         "Cell type, Cell name, Cell Id, Is used, Is modified, "
                         "Original attributes, Modified attributes}",
    Cells    = [hd(ets:lookup(Cells_ETS, R)) || R<-Refs],
    CellText = io_lib:format("~s\n~360p.\n", [DumpLine1,Cells]),
    file:write_file(DumpPath, list_to_binary(lists:flatten(CellText))).
    

get_cells_lines(Refs, Cells_ETS, DeleteNotUsed) ->
    lists:foldl(
        fun(Cell=#cell{m=M, b=B, t=T, n=N, used=Used, newattrs=NewAttrs},
                {_,MscUpd,MscDel,BscUpd,BscDel,BSCCells}) ->
            % Create BSCCells line
            CellLine = get_cell_line(Cell),
            %
            case {NewAttrs, (not Used) andalso DeleteNotUsed} of
                {[], true } -> % Delete not used cells
                    % Modify int GSM cells in MSC
                    MscDel2 =
                        case T of
                            "INT" -> ["MGCEE:CELL="++N++";\n" | MscDel];
                            _ -> MscDel
                        end,
                    BscCmd = "RLDEE:CELL="++N++";\n",
                    {M, MscUpd, MscDel2, BscUpd, [BscCmd|BscDel], BSCCells};
                {[], false} -> % Leave not used cells
                    {M, MscUpd, MscDel, BscUpd, BscDel, [CellLine|BSCCells]};
                {_,  _    } -> % Update used cells
                    Params = string:join([K++"="++V||{K,V}<-NewAttrs], ","),
                    BscCmd = "RLDEC:CELL="++N++","++Params++";\n",
                    % Modify int GSM cells in MSC
                    {MscUpd2, MscDel2} =
                        case T of
                            "INT" ->
                                {"CGI",CGI} = lists:keyfind("CGI",1,NewAttrs),
                                {["MGCEI:CELL="++N++",CGI="++CGI++
                                      ",BSC="++B++";\n" | MscUpd],
                                 ["MGCEE:CELL="++N++";\n" | MscDel]};
                            _ -> {MscUpd, MscDel}
                        end,
                    {M, MscUpd2, MscDel2, [BscCmd|BscUpd], BscDel,
                     [CellLine|BSCCells]}
             end
        end,
        {"", [], [], [], [], []},
        [hd(ets:lookup(Cells_ETS, R)) || R<-lists:reverse(Refs)]).

% Create BSCCells line
get_cell_line(#cell{s=S,m=M,b=B,t=T,n=N,i=I,attrs=Attrs,
        newattrs=NewAttrs}) ->
    IdField   = case T of "UTRAN"->"UTRANID"; _->"CGI" end,
    {Id, NewAttrs2} =
        case lists:keytake(IdField, 1, NewAttrs) of
            false                            -> {I,     NewAttrs};
            {value, {_,IdVal}, RemNewAttrs2} -> {IdVal, RemNewAttrs2}
        end,
    {Name, NewAttrs3} =
        case lists:keytake("NEWNAME", 1, NewAttrs2) of
            false                              -> {N,       NewAttrs2};
            {value, {_,NameVal}, RemNewAttrs3} -> {NameVal, RemNewAttrs3}
        end,
    Attrs3    = NewAttrs3++(Attrs--NewAttrs),
    Attrs3Str = string:join([K++"="++V||{K,V}<-Attrs3], ","),
    lists:flatten(io_lib:format(
            "sim=~s,msc=~s,bsc=~s,celltype=~s,CELL=~s,~s=~s,~s\n",
            [S,M,B,T,Name,IdField,Id,Attrs3Str])).

    
gen_updated_rels_mml(_S,B,Rels,Cells_ETS,OutDir) ->
    % MML script
    MMLPath = filename:join(OutDir, B++".rels.update.mml"),
    Rels1 = [{G,U} || {G, Us}<-Rels, U<-Us],
    Rels2 = [{G,U,lists:member({U,G},Rels1)} || {G,U}<-Rels1],
    Rels3 = [Rel || Rel={G,U,Mutual}<-Rels2, false=:=Mutual orelse G<U],
    Lines = ["e: sae:update(502, \"RQUCD\", ni, "++
             integer_to_list(erlang:max(?MaxBscRelationLimit, 2*length(Rels3)))++
             ", cell).\n",
             ".sleep 1\n" |
             [begin
                [#cell{newattrs=NewAttrs1}] = ets:lookup(Cells_ETS, R1),
                [#cell{newattrs=NewAttrs2}] = ets:lookup(Cells_ETS, R2),
                N1u =
                    case lists:keyfind("NEWNAME",1,NewAttrs1) of
                        false            -> N1;
                        {"NEWNAME", N1x} -> N1x
                    end,
                N2u =
                    case lists:keyfind("NEWNAME",1,NewAttrs2) of
                        false            -> N2;
                        {"NEWNAME", N2x} -> N2x
                    end,
                "RLNRI:CELL="++N1u++",CELLR="++N2u++
                if Mutual -> ";\n"; true -> ",SINGLE;\n" end
              end
              || {#halfrel{c=N1,cr=R1},#halfrel{c=N2,cr=R2},Mutual}<-Rels3]],
    file:write_file(MMLPath, list_to_binary(lists:flatten(Lines))),
    % Debug
    DbgPath  = filename:join(OutDir, B++".rels.update.csv"),
    DbgExPath  = filename:join(OutDir, B++".rels.update_ex.csv"),
    DbgLine1 = "# GsmNewCGI, UtranNewUTRANID\n",
    DbgExLine1 = "# Gsm sim idx, Gsm cell idx, Utran sim idx, Utran cell idx, "
                 "[Gsm lac, Gsm cid], [Utran lac, Utran cid, Utran RncId], "
                 "Old Gsm CGI, Old Utran UTRANID, "
                 "New Gsm CGI, New Utran UTRANID, "
                 "Direction\n",
    Dbg2Lines = [begin
                    [#cell{i=I1,newattrs=NewAttrs1}] = ets:lookup(Cells_ETS,R1),
                    [#cell{i=I2,newattrs=NewAttrs2}] = ets:lookup(Cells_ETS,R2),
                    I1u =
                        case lists:keyfind("CGI", 1, NewAttrs1) of
                            false   -> I1;
                            {_,I1b} -> I1b
                        end,
                    I2u =
                        case lists:keyfind("UTRANID", 1, NewAttrs2) of
                            false   -> I2;
                            {_,I2b} -> I2b
                        end,
                    MutualStr = if Mutual->"MUTUAL"; true->"SINGLE" end,
                    {lists:flatten(io_lib:format(
                        "~b,~b,~b,~b,   ~p,~p,   ~s,~s,   ~s,~s,   ~s\n",
                        [SX1,CX1,SX2,CX2,CGI1,CGI2,I1,I2,I1u,I2u,MutualStr])),
                     lists:flatten(io_lib:format(
                         "~s,~s\n",
                         [I1u,I2u]))}
                end
                || {#halfrel{sx=SX1,cx=CX1,cr=R1,part_cgi=CGI1},
                    #halfrel{sx=SX2,cx=CX2,cr=R2,part_cgi=CGI2},
                    Mutual}<-Rels3],
    {DbgExLines, DbgLines} = lists:unzip(Dbg2Lines),
    file:write_file(DbgPath,
                    list_to_binary(lists:flatten([DbgLine1|DbgLines]))),
    file:write_file(DbgExPath,
                    list_to_binary(lists:flatten([DbgExLine1|DbgExLines]))),
    % 
    Gs = [G ||{G,_U}<-Rels],
    Us = lists:usort([U ||{_G,U,_}<-Rels3]),
    % Dump relations
    RelsPath  = filename:join(OutDir, B++".rels.dump.erl"),
    RelsLine1 =
        "% [{{halfrel, Gsm sim idx, Gsm sim name, BSC idx, BSC name, "
                      "Gsm cell idx, Gsm cell name, Gsm cell reference, "
                      "[Gsm cell lac, Gsm cell cid], Properties},\n"
        "%   [{halfrel, Utran sim idx, Utran sim name, BSC idx, BSC name, "
                       "Utran cell idx, Utran cell name, Utran cell reference, "
                       "[Utran cell lac, Utran cell cid, Utrna cell rncid], "
                       "Properties}]}],",
    RelsText  = io_lib:format("~s\n~360p.\n", [RelsLine1,Rels]),
    file:write_file(RelsPath, list_to_binary(lists:flatten(RelsText))),
    % Dump GSM parts
    GCells      = lists:keysort(#cell.n, [hd(ets:lookup(Cells_ETS,R))
                                      ||#halfrel{cr=R}<-Gs]),
    GCellsPath  = filename:join(OutDir, B++".rels.INT.dump.erl"),
    GCellsLine1 = "% {cell, Cell reference, Sim name, MSC name, BSC name, "
                     "Cell type, Cell name, Cell Id, Is used, Is modified, "
                     "Original attributes, Modified attributes}",
    GCellsText  = io_lib:format("~s\n~360p.\n", [GCellsLine1,GCells]),
    file:write_file(GCellsPath, list_to_binary(lists:flatten(GCellsText))),
    % Dump UTRAN parts
    UCells      = lists:keysort(#cell.n, [hd(ets:lookup(Cells_ETS,R))
                                          ||#halfrel{cr=R}<-Us]),
    UCellsPath  = filename:join(OutDir, B++".rels.UTRAN.dump.erl"),
    UCellsLine1 = "% {cell, Cell reference, Sim name, MSC name, BSC name, "
                     "Cell type, Cell name, Cell Id, Is used, Is modified, "
                     "Original attributes, Modified attributes}",
    UCellsText  = io_lib:format("~s\n~360p.\n", [UCellsLine1,UCells]),
    file:write_file(UCellsPath, list_to_binary(lists:flatten(UCellsText))).
    


    
%%-----------------------------------------------------------------------------
%%  Build tables
%%-----------------------------------------------------------------------------

    
%%!-------------------------------------------------------------------
%% store_cells -- 
%% 
%% store_cells() -> Result
%%   
%% 
%%--------------------------------------------------------------------
store_cells(BSCCells, GS_GBs) ->
    % Cell table
    Cells_ETS       = ets:new(cells, [{keypos,#cell.r}]),
    % Cells of a Simulation/BSC/CellType: list of cell references
    SimBsc_Ref_ETS  = ets:new(sim_bsc_eurefs, []),
    % Cells with same CellId: list of reference
    CellId_Ref_ETS  = ets:new(cell_id_refs,   []),
    % Initialize cells of Sim/BSC/CellType with empty list
    [begin
        ets:insert(SimBsc_Ref_ETS,{{GS,GB,"INT"},[]}),
        ets:insert(SimBsc_Ref_ETS,{{GS,GB,"EXT"},[]}),
        ets:insert(SimBsc_Ref_ETS,{{GS,GB,"UTRAN"},[]})
     end
     || {GS,GBs}<-GS_GBs, GB<-GBs],
    % Store cells
    lists:foreach(
        fun(Cell=#cell{r=R,s=S,b=B,t=T,i=I}) ->
            % Store cell
            ets:insert(Cells_ETS, Cell),
            % Update references of same Sim/BSC/CellType
            [{{S,B,T},Rs2}] = ets:lookup(SimBsc_Ref_ETS, {S,B,T}),
            ets:insert(SimBsc_Ref_ETS,{{S,B,T},[R|Rs2]}),
            % Update references of same cell identity
            case ets:lookup(CellId_Ref_ETS, I) of
                [{I,Rs3}] -> ets:insert(CellId_Ref_ETS, {I,[R|Rs3]});
                []        -> ets:insert(CellId_Ref_ETS, {I,[R]})
            end
        end,
        lists:reverse(BSCCells)),
    % Return the cell-, Sim/BSC/CellType- and the CellId tables
    {Cells_ETS, SimBsc_Ref_ETS, CellId_Ref_ETS}.


%%!-------------------------------------------------------------------
%% create_utran_table -- Create table of attributes of expected UTRAN cells
%% 
%% create_utran_table() -> Result
%%   
%% Create table of attributes of expected UTRAN cells
%%--------------------------------------------------------------------
create_utran_table(UtranParams, _ExpRels) ->
    UtranParams_ETS = ets:new(utran_params, [{keypos,#utranparam.cid}]),
    lists:foreach(
        fun(UtranParam=#utranparam{}) ->
            ets:insert(UtranParams_ETS, UtranParam)
        end,
        UtranParams),
    UtranParams_ETS.



%%=============================================================================
%%  Low level functions
%%=============================================================================


read_csv(FilePath) ->
    case file:open(FilePath, [read]) of
        {ok, Dev} ->
            Lines = read_csv_(Dev),
            file:close(Dev),
            Lines;
        {error, _Reason} ->
            []
    end.

read_csv_(Dev) ->
    case file:read_line(Dev) of
        {ok, Line} ->
            case string:strip(string:strip(Line, right, $\n)) of
                ""     -> read_csv_(Dev);
                [$#|_] -> read_csv_(Dev);
                Str    ->
                    [list_to_tuple([string:strip(S)
                                    || S<-string:tokens(Str,",")])
                     | read_csv_(Dev)]
            end;
        _ ->
            []
    end.


