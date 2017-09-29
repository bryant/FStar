open Prims
type z3_replay_result =
  (FStar_SMTEncoding_Z3.unsat_core,FStar_SMTEncoding_Term.error_labels)
    FStar_Util.either[@@deriving show]
let z3_result_as_replay_result:
  'Auu____13 'Auu____14 'Auu____15 .
    ('Auu____15,('Auu____14,'Auu____13) FStar_Pervasives_Native.tuple2)
      FStar_Util.either -> ('Auu____15,'Auu____14) FStar_Util.either
  =
  fun uu___87_31  ->
    match uu___87_31 with
    | FStar_Util.Inl l -> FStar_Util.Inl l
    | FStar_Util.Inr (r,uu____46) -> FStar_Util.Inr r
let recorded_hints:
  FStar_Util.hints FStar_Pervasives_Native.option FStar_ST.ref =
  FStar_Util.mk_ref FStar_Pervasives_Native.None
let replaying_hints:
  FStar_Util.hints FStar_Pervasives_Native.option FStar_ST.ref =
  FStar_Util.mk_ref FStar_Pervasives_Native.None
let format_hints_file_name: Prims.string -> Prims.string =
  fun src_filename  -> FStar_Util.format1 "%s.hints" src_filename
let initialize_hints_db:
  'Auu____87 . Prims.string -> 'Auu____87 -> Prims.unit =
  fun src_filename  ->
    fun format_filename  ->
      (let uu____97 = FStar_Options.record_hints () in
       if uu____97
       then
         FStar_ST.op_Colon_Equals recorded_hints
           (FStar_Pervasives_Native.Some [])
       else ());
      (let uu____155 = FStar_Options.use_hints () in
       if uu____155
       then
         let norm_src_filename = FStar_Util.normalize_file_path src_filename in
         let val_filename =
           let uu____158 = FStar_Options.hint_file () in
           match uu____158 with
           | FStar_Pervasives_Native.Some fn -> fn
           | FStar_Pervasives_Native.None  ->
               format_hints_file_name norm_src_filename in
         let uu____162 = FStar_Util.read_hints val_filename in
         match uu____162 with
         | FStar_Pervasives_Native.Some hints ->
             let expected_digest =
               FStar_Util.digest_of_file norm_src_filename in
             ((let uu____168 = FStar_Options.hint_info () in
               if uu____168
               then
                 let uu____169 =
                   let uu____170 = FStar_Options.hint_file () in
                   match uu____170 with
                   | FStar_Pervasives_Native.Some fn ->
                       Prims.strcat " from '" (Prims.strcat val_filename "'")
                   | uu____174 -> "" in
                 FStar_Util.print3 "(%s) digest is %s%s.\n" norm_src_filename
                   (if hints.FStar_Util.module_digest = expected_digest
                    then "valid; using hints"
                    else "invalid; using potentially stale hints") uu____169
               else ());
              FStar_ST.op_Colon_Equals replaying_hints
                (FStar_Pervasives_Native.Some (hints.FStar_Util.hints)))
         | FStar_Pervasives_Native.None  ->
             let uu____229 = FStar_Options.hint_info () in
             (if uu____229
              then
                FStar_Util.print1 "(%s) Unable to read hint file.\n"
                  norm_src_filename
              else ())
       else ())
let finalize_hints_db: Prims.string -> Prims.unit =
  fun src_filename  ->
    (let uu____237 = FStar_Options.record_hints () in
     if uu____237
     then
       let hints =
         let uu____239 = FStar_ST.op_Bang recorded_hints in
         FStar_Option.get uu____239 in
       let hints_db =
         let uu____293 = FStar_Util.digest_of_file src_filename in
         { FStar_Util.module_digest = uu____293; FStar_Util.hints = hints } in
       let norm_src_filename = FStar_Util.normalize_file_path src_filename in
       let val_filename =
         let uu____296 = FStar_Options.hint_file () in
         match uu____296 with
         | FStar_Pervasives_Native.Some fn -> fn
         | FStar_Pervasives_Native.None  ->
             format_hints_file_name norm_src_filename in
       FStar_Util.write_hints val_filename hints_db
     else ());
    FStar_ST.op_Colon_Equals recorded_hints FStar_Pervasives_Native.None;
    FStar_ST.op_Colon_Equals replaying_hints FStar_Pervasives_Native.None
let with_hints_db: 'a . Prims.string -> (Prims.unit -> 'a) -> 'a =
  fun fname  ->
    fun f  ->
      initialize_hints_db fname false;
      (let result = f () in finalize_hints_db fname; result)
let filter_using_facts_from:
  FStar_TypeChecker_Env.env ->
    FStar_SMTEncoding_Term.decls_t -> FStar_SMTEncoding_Term.decl Prims.list
  =
  fun e  ->
    fun theory  ->
      let should_enc_fid fid =
        match fid with
        | FStar_SMTEncoding_Term.Namespace lid ->
            FStar_TypeChecker_Env.should_enc_lid e lid
        | uu____440 -> false in
      let matches_fact_ids include_assumption_names a =
        match a.FStar_SMTEncoding_Term.assumption_fact_ids with
        | [] -> true
        | uu____452 ->
            (FStar_List.contains a.FStar_SMTEncoding_Term.assumption_name
               include_assumption_names)
              ||
              (FStar_All.pipe_right
                 a.FStar_SMTEncoding_Term.assumption_fact_ids
                 (FStar_Util.for_some (fun fid  -> should_enc_fid fid))) in
      let theory_rev = FStar_List.rev theory in
      let uu____462 =
        FStar_List.fold_left
          (fun uu____485  ->
             fun d  ->
               match uu____485 with
               | (out,include_assumption_names) ->
                   (match d with
                    | FStar_SMTEncoding_Term.Assume a ->
                        let uu____522 =
                          matches_fact_ids include_assumption_names a in
                        if uu____522
                        then ((d :: out), include_assumption_names)
                        else (out, include_assumption_names)
                    | FStar_SMTEncoding_Term.RetainAssumptions names1 ->
                        ((d :: out),
                          (FStar_List.append names1 include_assumption_names))
                    | uu____547 -> ((d :: out), include_assumption_names)))
          ([], []) theory_rev in
      match uu____462 with | (pruned_theory,uu____559) -> pruned_theory
let filter_assertions:
  FStar_TypeChecker_Env.env ->
    FStar_SMTEncoding_Z3.unsat_core ->
      FStar_SMTEncoding_Term.decls_t ->
        (FStar_SMTEncoding_Term.decl Prims.list,Prims.bool)
          FStar_Pervasives_Native.tuple2
  =
  fun e  ->
    fun core  ->
      fun theory  ->
        match core with
        | FStar_Pervasives_Native.None  ->
            let uu____594 = filter_using_facts_from e theory in
            (uu____594, false)
        | FStar_Pervasives_Native.Some core1 ->
            let uu____604 =
              FStar_List.fold_right
                (fun d  ->
                   fun uu____628  ->
                     match uu____628 with
                     | (theory1,n_retained,n_pruned) ->
                         (match d with
                          | FStar_SMTEncoding_Term.Assume a ->
                              if
                                FStar_List.contains
                                  a.FStar_SMTEncoding_Term.assumption_name
                                  core1
                              then
                                ((d :: theory1),
                                  (n_retained + (Prims.parse_int "1")),
                                  n_pruned)
                              else
                                if
                                  FStar_Util.starts_with
                                    a.FStar_SMTEncoding_Term.assumption_name
                                    "@"
                                then ((d :: theory1), n_retained, n_pruned)
                                else
                                  (theory1, n_retained,
                                    (n_pruned + (Prims.parse_int "1")))
                          | uu____685 ->
                              ((d :: theory1), n_retained, n_pruned))) theory
                ([], (Prims.parse_int "0"), (Prims.parse_int "0")) in
            (match uu____604 with
             | (theory',n_retained,n_pruned) ->
                 let uu____703 =
                   let uu____706 =
                     let uu____709 =
                       let uu____710 =
                         let uu____711 =
                           FStar_All.pipe_right core1
                             (FStar_String.concat ", ") in
                         Prims.strcat "UNSAT CORE: " uu____711 in
                       FStar_SMTEncoding_Term.Caption uu____710 in
                     [uu____709] in
                   FStar_List.append theory' uu____706 in
                 (uu____703, true))
let filter_facts_without_core:
  FStar_TypeChecker_Env.env ->
    FStar_SMTEncoding_Term.decls_t ->
      (FStar_SMTEncoding_Term.decl Prims.list,Prims.bool)
        FStar_Pervasives_Native.tuple2
  =
  fun e  ->
    fun x  ->
      let uu____730 = filter_using_facts_from e x in (uu____730, false)
type errors =
  {
  error_reason: Prims.string;
  error_fuel: Prims.int;
  error_ifuel: Prims.int;
  error_hint: Prims.string Prims.list FStar_Pervasives_Native.option;
  error_messages:
    (Prims.string,FStar_Range.range) FStar_Pervasives_Native.tuple2
      Prims.list;}[@@deriving show]
let __proj__Mkerrors__item__error_reason: errors -> Prims.string =
  fun projectee  ->
    match projectee with
    | { error_reason = __fname__error_reason;
        error_fuel = __fname__error_fuel; error_ifuel = __fname__error_ifuel;
        error_hint = __fname__error_hint;
        error_messages = __fname__error_messages;_} -> __fname__error_reason
let __proj__Mkerrors__item__error_fuel: errors -> Prims.int =
  fun projectee  ->
    match projectee with
    | { error_reason = __fname__error_reason;
        error_fuel = __fname__error_fuel; error_ifuel = __fname__error_ifuel;
        error_hint = __fname__error_hint;
        error_messages = __fname__error_messages;_} -> __fname__error_fuel
let __proj__Mkerrors__item__error_ifuel: errors -> Prims.int =
  fun projectee  ->
    match projectee with
    | { error_reason = __fname__error_reason;
        error_fuel = __fname__error_fuel; error_ifuel = __fname__error_ifuel;
        error_hint = __fname__error_hint;
        error_messages = __fname__error_messages;_} -> __fname__error_ifuel
let __proj__Mkerrors__item__error_hint:
  errors -> Prims.string Prims.list FStar_Pervasives_Native.option =
  fun projectee  ->
    match projectee with
    | { error_reason = __fname__error_reason;
        error_fuel = __fname__error_fuel; error_ifuel = __fname__error_ifuel;
        error_hint = __fname__error_hint;
        error_messages = __fname__error_messages;_} -> __fname__error_hint
let __proj__Mkerrors__item__error_messages:
  errors ->
    (Prims.string,FStar_Range.range) FStar_Pervasives_Native.tuple2
      Prims.list
  =
  fun projectee  ->
    match projectee with
    | { error_reason = __fname__error_reason;
        error_fuel = __fname__error_fuel; error_ifuel = __fname__error_ifuel;
        error_hint = __fname__error_hint;
        error_messages = __fname__error_messages;_} ->
        __fname__error_messages
let error_to_short_string: errors -> Prims.string =
  fun err1  ->
    let uu____884 = FStar_Util.string_of_int err1.error_fuel in
    let uu____885 = FStar_Util.string_of_int err1.error_ifuel in
    FStar_Util.format4 "%s (fuel=%s; ifuel=%s; %s)" err1.error_reason
      uu____884 uu____885
      (if FStar_Option.isSome err1.error_hint then "with hint" else "")
type query_settings =
  {
  query_env: FStar_TypeChecker_Env.env;
  query_decl: FStar_SMTEncoding_Term.decl;
  query_name: Prims.string;
  query_index: Prims.int;
  query_range: FStar_Range.range;
  query_fuel: Prims.int;
  query_ifuel: Prims.int;
  query_rlimit: Prims.int;
  query_hint: FStar_SMTEncoding_Z3.unsat_core;
  query_errors: errors Prims.list;
  query_all_labels: FStar_SMTEncoding_Term.error_labels;
  query_suffix: FStar_SMTEncoding_Term.decl Prims.list;
  query_hash: Prims.string FStar_Pervasives_Native.option;}[@@deriving show]
let __proj__Mkquery_settings__item__query_env:
  query_settings -> FStar_TypeChecker_Env.env =
  fun projectee  ->
    match projectee with
    | { query_env = __fname__query_env; query_decl = __fname__query_decl;
        query_name = __fname__query_name; query_index = __fname__query_index;
        query_range = __fname__query_range; query_fuel = __fname__query_fuel;
        query_ifuel = __fname__query_ifuel;
        query_rlimit = __fname__query_rlimit;
        query_hint = __fname__query_hint;
        query_errors = __fname__query_errors;
        query_all_labels = __fname__query_all_labels;
        query_suffix = __fname__query_suffix;
        query_hash = __fname__query_hash;_} -> __fname__query_env
let __proj__Mkquery_settings__item__query_decl:
  query_settings -> FStar_SMTEncoding_Term.decl =
  fun projectee  ->
    match projectee with
    | { query_env = __fname__query_env; query_decl = __fname__query_decl;
        query_name = __fname__query_name; query_index = __fname__query_index;
        query_range = __fname__query_range; query_fuel = __fname__query_fuel;
        query_ifuel = __fname__query_ifuel;
        query_rlimit = __fname__query_rlimit;
        query_hint = __fname__query_hint;
        query_errors = __fname__query_errors;
        query_all_labels = __fname__query_all_labels;
        query_suffix = __fname__query_suffix;
        query_hash = __fname__query_hash;_} -> __fname__query_decl
let __proj__Mkquery_settings__item__query_name:
  query_settings -> Prims.string =
  fun projectee  ->
    match projectee with
    | { query_env = __fname__query_env; query_decl = __fname__query_decl;
        query_name = __fname__query_name; query_index = __fname__query_index;
        query_range = __fname__query_range; query_fuel = __fname__query_fuel;
        query_ifuel = __fname__query_ifuel;
        query_rlimit = __fname__query_rlimit;
        query_hint = __fname__query_hint;
        query_errors = __fname__query_errors;
        query_all_labels = __fname__query_all_labels;
        query_suffix = __fname__query_suffix;
        query_hash = __fname__query_hash;_} -> __fname__query_name
let __proj__Mkquery_settings__item__query_index: query_settings -> Prims.int
  =
  fun projectee  ->
    match projectee with
    | { query_env = __fname__query_env; query_decl = __fname__query_decl;
        query_name = __fname__query_name; query_index = __fname__query_index;
        query_range = __fname__query_range; query_fuel = __fname__query_fuel;
        query_ifuel = __fname__query_ifuel;
        query_rlimit = __fname__query_rlimit;
        query_hint = __fname__query_hint;
        query_errors = __fname__query_errors;
        query_all_labels = __fname__query_all_labels;
        query_suffix = __fname__query_suffix;
        query_hash = __fname__query_hash;_} -> __fname__query_index
let __proj__Mkquery_settings__item__query_range:
  query_settings -> FStar_Range.range =
  fun projectee  ->
    match projectee with
    | { query_env = __fname__query_env; query_decl = __fname__query_decl;
        query_name = __fname__query_name; query_index = __fname__query_index;
        query_range = __fname__query_range; query_fuel = __fname__query_fuel;
        query_ifuel = __fname__query_ifuel;
        query_rlimit = __fname__query_rlimit;
        query_hint = __fname__query_hint;
        query_errors = __fname__query_errors;
        query_all_labels = __fname__query_all_labels;
        query_suffix = __fname__query_suffix;
        query_hash = __fname__query_hash;_} -> __fname__query_range
let __proj__Mkquery_settings__item__query_fuel: query_settings -> Prims.int =
  fun projectee  ->
    match projectee with
    | { query_env = __fname__query_env; query_decl = __fname__query_decl;
        query_name = __fname__query_name; query_index = __fname__query_index;
        query_range = __fname__query_range; query_fuel = __fname__query_fuel;
        query_ifuel = __fname__query_ifuel;
        query_rlimit = __fname__query_rlimit;
        query_hint = __fname__query_hint;
        query_errors = __fname__query_errors;
        query_all_labels = __fname__query_all_labels;
        query_suffix = __fname__query_suffix;
        query_hash = __fname__query_hash;_} -> __fname__query_fuel
let __proj__Mkquery_settings__item__query_ifuel: query_settings -> Prims.int
  =
  fun projectee  ->
    match projectee with
    | { query_env = __fname__query_env; query_decl = __fname__query_decl;
        query_name = __fname__query_name; query_index = __fname__query_index;
        query_range = __fname__query_range; query_fuel = __fname__query_fuel;
        query_ifuel = __fname__query_ifuel;
        query_rlimit = __fname__query_rlimit;
        query_hint = __fname__query_hint;
        query_errors = __fname__query_errors;
        query_all_labels = __fname__query_all_labels;
        query_suffix = __fname__query_suffix;
        query_hash = __fname__query_hash;_} -> __fname__query_ifuel
let __proj__Mkquery_settings__item__query_rlimit: query_settings -> Prims.int
  =
  fun projectee  ->
    match projectee with
    | { query_env = __fname__query_env; query_decl = __fname__query_decl;
        query_name = __fname__query_name; query_index = __fname__query_index;
        query_range = __fname__query_range; query_fuel = __fname__query_fuel;
        query_ifuel = __fname__query_ifuel;
        query_rlimit = __fname__query_rlimit;
        query_hint = __fname__query_hint;
        query_errors = __fname__query_errors;
        query_all_labels = __fname__query_all_labels;
        query_suffix = __fname__query_suffix;
        query_hash = __fname__query_hash;_} -> __fname__query_rlimit
let __proj__Mkquery_settings__item__query_hint:
  query_settings -> FStar_SMTEncoding_Z3.unsat_core =
  fun projectee  ->
    match projectee with
    | { query_env = __fname__query_env; query_decl = __fname__query_decl;
        query_name = __fname__query_name; query_index = __fname__query_index;
        query_range = __fname__query_range; query_fuel = __fname__query_fuel;
        query_ifuel = __fname__query_ifuel;
        query_rlimit = __fname__query_rlimit;
        query_hint = __fname__query_hint;
        query_errors = __fname__query_errors;
        query_all_labels = __fname__query_all_labels;
        query_suffix = __fname__query_suffix;
        query_hash = __fname__query_hash;_} -> __fname__query_hint
let __proj__Mkquery_settings__item__query_errors:
  query_settings -> errors Prims.list =
  fun projectee  ->
    match projectee with
    | { query_env = __fname__query_env; query_decl = __fname__query_decl;
        query_name = __fname__query_name; query_index = __fname__query_index;
        query_range = __fname__query_range; query_fuel = __fname__query_fuel;
        query_ifuel = __fname__query_ifuel;
        query_rlimit = __fname__query_rlimit;
        query_hint = __fname__query_hint;
        query_errors = __fname__query_errors;
        query_all_labels = __fname__query_all_labels;
        query_suffix = __fname__query_suffix;
        query_hash = __fname__query_hash;_} -> __fname__query_errors
let __proj__Mkquery_settings__item__query_all_labels:
  query_settings -> FStar_SMTEncoding_Term.error_labels =
  fun projectee  ->
    match projectee with
    | { query_env = __fname__query_env; query_decl = __fname__query_decl;
        query_name = __fname__query_name; query_index = __fname__query_index;
        query_range = __fname__query_range; query_fuel = __fname__query_fuel;
        query_ifuel = __fname__query_ifuel;
        query_rlimit = __fname__query_rlimit;
        query_hint = __fname__query_hint;
        query_errors = __fname__query_errors;
        query_all_labels = __fname__query_all_labels;
        query_suffix = __fname__query_suffix;
        query_hash = __fname__query_hash;_} -> __fname__query_all_labels
let __proj__Mkquery_settings__item__query_suffix:
  query_settings -> FStar_SMTEncoding_Term.decl Prims.list =
  fun projectee  ->
    match projectee with
    | { query_env = __fname__query_env; query_decl = __fname__query_decl;
        query_name = __fname__query_name; query_index = __fname__query_index;
        query_range = __fname__query_range; query_fuel = __fname__query_fuel;
        query_ifuel = __fname__query_ifuel;
        query_rlimit = __fname__query_rlimit;
        query_hint = __fname__query_hint;
        query_errors = __fname__query_errors;
        query_all_labels = __fname__query_all_labels;
        query_suffix = __fname__query_suffix;
        query_hash = __fname__query_hash;_} -> __fname__query_suffix
let __proj__Mkquery_settings__item__query_hash:
  query_settings -> Prims.string FStar_Pervasives_Native.option =
  fun projectee  ->
    match projectee with
    | { query_env = __fname__query_env; query_decl = __fname__query_decl;
        query_name = __fname__query_name; query_index = __fname__query_index;
        query_range = __fname__query_range; query_fuel = __fname__query_fuel;
        query_ifuel = __fname__query_ifuel;
        query_rlimit = __fname__query_rlimit;
        query_hint = __fname__query_hint;
        query_errors = __fname__query_errors;
        query_all_labels = __fname__query_all_labels;
        query_suffix = __fname__query_suffix;
        query_hash = __fname__query_hash;_} -> __fname__query_hash
let with_fuel_and_diagnostics:
  query_settings ->
    FStar_SMTEncoding_Term.decl Prims.list ->
      FStar_SMTEncoding_Term.decl Prims.list
  =
  fun settings  ->
    fun label_assumptions  ->
      let n1 = settings.query_fuel in
      let i = settings.query_ifuel in
      let rlimit = settings.query_rlimit in
      let uu____1275 =
        let uu____1278 =
          let uu____1279 =
            let uu____1280 = FStar_Util.string_of_int n1 in
            let uu____1281 = FStar_Util.string_of_int i in
            FStar_Util.format2 "<fuel='%s' ifuel='%s'>" uu____1280 uu____1281 in
          FStar_SMTEncoding_Term.Caption uu____1279 in
        let uu____1282 =
          let uu____1285 =
            let uu____1286 =
              let uu____1293 =
                let uu____1294 =
                  let uu____1299 =
                    FStar_SMTEncoding_Util.mkApp ("MaxFuel", []) in
                  let uu____1302 = FStar_SMTEncoding_Term.n_fuel n1 in
                  (uu____1299, uu____1302) in
                FStar_SMTEncoding_Util.mkEq uu____1294 in
              (uu____1293, FStar_Pervasives_Native.None,
                "@MaxFuel_assumption") in
            FStar_SMTEncoding_Util.mkAssume uu____1286 in
          let uu____1305 =
            let uu____1308 =
              let uu____1309 =
                let uu____1316 =
                  let uu____1317 =
                    let uu____1322 =
                      FStar_SMTEncoding_Util.mkApp ("MaxIFuel", []) in
                    let uu____1325 = FStar_SMTEncoding_Term.n_fuel i in
                    (uu____1322, uu____1325) in
                  FStar_SMTEncoding_Util.mkEq uu____1317 in
                (uu____1316, FStar_Pervasives_Native.None,
                  "@MaxIFuel_assumption") in
              FStar_SMTEncoding_Util.mkAssume uu____1309 in
            [uu____1308; settings.query_decl] in
          uu____1285 :: uu____1305 in
        uu____1278 :: uu____1282 in
      let uu____1328 =
        let uu____1331 =
          let uu____1334 =
            let uu____1337 =
              let uu____1338 =
                let uu____1343 = FStar_Util.string_of_int rlimit in
                ("rlimit", uu____1343) in
              FStar_SMTEncoding_Term.SetOption uu____1338 in
            [uu____1337;
            FStar_SMTEncoding_Term.CheckSat;
            FStar_SMTEncoding_Term.GetReasonUnknown] in
          let uu____1344 =
            let uu____1347 =
              let uu____1350 = FStar_Options.record_hints () in
              if uu____1350
              then [FStar_SMTEncoding_Term.GetUnsatCore]
              else [] in
            let uu____1354 =
              let uu____1357 =
                let uu____1360 = FStar_Options.print_z3_statistics () in
                if uu____1360
                then [FStar_SMTEncoding_Term.GetStatistics]
                else [] in
              FStar_List.append uu____1357 settings.query_suffix in
            FStar_List.append uu____1347 uu____1354 in
          FStar_List.append uu____1334 uu____1344 in
        FStar_List.append label_assumptions uu____1331 in
      FStar_List.append uu____1275 uu____1328
let used_hint: query_settings -> Prims.bool =
  fun s  -> FStar_Option.isSome s.query_hint
let next_hint:
  query_settings -> FStar_Util.hint FStar_Pervasives_Native.option =
  fun uu____1375  ->
    match uu____1375 with
    | { query_env = uu____1378; query_decl = uu____1379; query_name = qname;
        query_index = qindex; query_range = uu____1382;
        query_fuel = uu____1383; query_ifuel = uu____1384;
        query_rlimit = uu____1385; query_hint = uu____1386;
        query_errors = uu____1387; query_all_labels = uu____1388;
        query_suffix = uu____1389; query_hash = uu____1390;_} ->
        let uu____1397 = FStar_ST.op_Bang replaying_hints in
        (match uu____1397 with
         | FStar_Pervasives_Native.Some hints ->
             FStar_Util.find_map hints
               (fun uu___88_1457  ->
                  match uu___88_1457 with
                  | FStar_Pervasives_Native.Some hint when
                      (hint.FStar_Util.hint_name = qname) &&
                        (hint.FStar_Util.hint_index = qindex)
                      -> FStar_Pervasives_Native.Some hint
                  | uu____1463 -> FStar_Pervasives_Native.None)
         | uu____1466 -> FStar_Pervasives_Native.None)
let query_errors:
  'Auu____1479 'Auu____1480 'Auu____1481 .
    query_settings ->
      (FStar_SMTEncoding_Z3.z3status,'Auu____1481,'Auu____1480,'Auu____1479)
        FStar_Pervasives_Native.tuple4 ->
        errors FStar_Pervasives_Native.option
  =
  fun settings  ->
    fun uu____1499  ->
      match uu____1499 with
      | (z3status,elapsed_time,stats,hash) ->
          (match z3status with
           | FStar_SMTEncoding_Z3.UNSAT uu____1514 ->
               FStar_Pervasives_Native.None
           | uu____1515 ->
               let uu____1516 =
                 FStar_SMTEncoding_Z3.status_string_and_errors z3status in
               (match uu____1516 with
                | (msg,error_labels) ->
                    let err1 =
                      let uu____1526 =
                        FStar_List.map
                          (fun uu____1547  ->
                             match uu____1547 with
                             | (uu____1558,x,y) -> (x, y)) error_labels in
                      {
                        error_reason = msg;
                        error_fuel = (settings.query_fuel);
                        error_ifuel = (settings.query_ifuel);
                        error_hint = (settings.query_hint);
                        error_messages = uu____1526
                      } in
                    FStar_Pervasives_Native.Some err1))
let detail_hint_replay:
  'Auu____1571 'Auu____1572 'Auu____1573 .
    query_settings ->
      (FStar_SMTEncoding_Z3.z3status,'Auu____1573,'Auu____1572,'Auu____1571)
        FStar_Pervasives_Native.tuple4 -> Prims.unit
  =
  fun settings  ->
    fun uu____1589  ->
      match uu____1589 with
      | (z3status,uu____1599,uu____1600,uu____1601) ->
          let uu____1602 =
            (used_hint settings) && (FStar_Options.detail_hint_replay ()) in
          if uu____1602
          then
            (match z3status with
             | FStar_SMTEncoding_Z3.UNSAT uu____1603 -> ()
             | _failed ->
                 let ask_z3 label_assumptions =
                   let res = FStar_Util.mk_ref FStar_Pervasives_Native.None in
                   (let uu____1621 =
                      with_fuel_and_diagnostics settings label_assumptions in
                    FStar_SMTEncoding_Z3.ask
                      (filter_assertions settings.query_env
                         settings.query_hint)
                      ((settings.query_hash), (settings.query_hint))
                      settings.query_all_labels uu____1621
                      FStar_Pervasives_Native.None
                      (fun r  ->
                         FStar_ST.op_Colon_Equals res
                           (FStar_Pervasives_Native.Some r)));
                   (let uu____1692 = FStar_ST.op_Bang res in
                    FStar_Option.get uu____1692) in
                 FStar_SMTEncoding_ErrorReporting.detail_errors true
                   settings.query_env settings.query_all_labels ask_z3)
          else ()
let find_localized_errors:
  errors Prims.list -> errors FStar_Pervasives_Native.option =
  fun errs  ->
    FStar_All.pipe_right errs
      (FStar_List.tryFind
         (fun err1  ->
            match err1.error_messages with | [] -> false | uu____1780 -> true))
let has_localized_errors: errors Prims.list -> Prims.bool =
  fun errs  ->
    let uu____1795 = find_localized_errors errs in
    FStar_Option.isSome uu____1795
let report_errors: query_settings -> Prims.unit =
  fun settings  ->
    let uu____1802 =
      (FStar_Options.detail_errors ()) &&
        (let uu____1804 = FStar_Options.n_cores () in
         uu____1804 = (Prims.parse_int "1")) in
    if uu____1802
    then
      let initial_fuel1 =
        let uu___89_1806 = settings in
        let uu____1807 = FStar_Options.initial_fuel () in
        let uu____1808 = FStar_Options.initial_ifuel () in
        {
          query_env = (uu___89_1806.query_env);
          query_decl = (uu___89_1806.query_decl);
          query_name = (uu___89_1806.query_name);
          query_index = (uu___89_1806.query_index);
          query_range = (uu___89_1806.query_range);
          query_fuel = uu____1807;
          query_ifuel = uu____1808;
          query_rlimit = (uu___89_1806.query_rlimit);
          query_hint = FStar_Pervasives_Native.None;
          query_errors = (uu___89_1806.query_errors);
          query_all_labels = (uu___89_1806.query_all_labels);
          query_suffix = (uu___89_1806.query_suffix);
          query_hash = (uu___89_1806.query_hash)
        } in
      let ask_z3 label_assumptions =
        let res = FStar_Util.mk_ref FStar_Pervasives_Native.None in
        (let uu____1827 =
           with_fuel_and_diagnostics initial_fuel1 label_assumptions in
         FStar_SMTEncoding_Z3.ask
           (filter_facts_without_core settings.query_env)
           ((settings.query_hash), FStar_Pervasives_Native.None)
           settings.query_all_labels uu____1827 FStar_Pervasives_Native.None
           (fun r  ->
              FStar_ST.op_Colon_Equals res (FStar_Pervasives_Native.Some r)));
        (let uu____1904 = FStar_ST.op_Bang res in FStar_Option.get uu____1904) in
      FStar_SMTEncoding_ErrorReporting.detail_errors false settings.query_env
        settings.query_all_labels ask_z3
    else
      (let uu____1972 = find_localized_errors settings.query_errors in
       match uu____1972 with
       | FStar_Pervasives_Native.Some err1 ->
           (FStar_All.pipe_right settings.query_errors
              (FStar_List.iter
                 (fun e  ->
                    let uu____1982 =
                      let uu____1983 = error_to_short_string e in
                      Prims.strcat "SMT solver says: " uu____1983 in
                    FStar_Errors.diag settings.query_range uu____1982));
            FStar_TypeChecker_Err.add_errors settings.query_env
              err1.error_messages)
       | FStar_Pervasives_Native.None  ->
           let err_detail =
             let uu____1985 =
               FStar_All.pipe_right settings.query_errors
                 (FStar_List.map
                    (fun e  ->
                       let uu____1995 = error_to_short_string e in
                       Prims.strcat "SMT solver says: " uu____1995)) in
             FStar_All.pipe_right uu____1985 (FStar_String.concat "; ") in
           let uu____1998 =
             let uu____2005 =
               let uu____2010 =
                 FStar_Util.format1 "Unknown assertion failed (%s)"
                   err_detail in
               (uu____2010, (settings.query_range)) in
             [uu____2005] in
           FStar_TypeChecker_Err.add_errors settings.query_env uu____1998)
let query_info:
  'Auu____2025 .
    query_settings ->
      (FStar_SMTEncoding_Z3.z3status,Prims.int,Prims.string FStar_Util.smap,
        'Auu____2025) FStar_Pervasives_Native.tuple4 -> Prims.unit
  =
  fun settings  ->
    fun z3result  ->
      let uu____2054 =
        (FStar_Options.hint_info ()) ||
          (FStar_Options.print_z3_statistics ()) in
      if uu____2054
      then
        let uu____2055 = z3result in
        match uu____2055 with
        | (z3status,elapsed_time,statistics,uu____2069) ->
            let uu____2074 =
              FStar_SMTEncoding_Z3.status_string_and_errors z3status in
            (match uu____2074 with
             | (status_string,errs) ->
                 let tag =
                   match z3status with
                   | FStar_SMTEncoding_Z3.UNSAT uu____2082 -> "succeeded"
                   | uu____2083 ->
                       Prims.strcat "failed {reason-unknown="
                         (Prims.strcat status_string "}") in
                 let range =
                   let uu____2085 =
                     let uu____2086 =
                       FStar_Range.string_of_range settings.query_range in
                     let uu____2087 =
                       let uu____2088 = FStar_SMTEncoding_Z3.at_log_file () in
                       Prims.strcat uu____2088 ")" in
                     Prims.strcat uu____2086 uu____2087 in
                   Prims.strcat "(" uu____2085 in
                 let used_hint_tag =
                   if used_hint settings then " (with hint)" else "" in
                 let stats =
                   let uu____2092 = FStar_Options.print_z3_statistics () in
                   if uu____2092
                   then
                     let f k v1 a =
                       Prims.strcat a
                         (Prims.strcat k
                            (Prims.strcat "=" (Prims.strcat v1 " "))) in
                     let str =
                       FStar_Util.smap_fold statistics f "statistics={" in
                     let uu____2104 =
                       FStar_Util.substring str (Prims.parse_int "0")
                         ((FStar_String.length str) - (Prims.parse_int "1")) in
                     Prims.strcat uu____2104 "}"
                   else "" in
                 ((let uu____2107 =
                     let uu____2110 =
                       let uu____2113 =
                         let uu____2116 =
                           FStar_Util.string_of_int settings.query_index in
                         let uu____2117 =
                           let uu____2120 =
                             let uu____2123 =
                               let uu____2126 =
                                 FStar_Util.string_of_int elapsed_time in
                               let uu____2127 =
                                 let uu____2130 =
                                   FStar_Util.string_of_int
                                     settings.query_fuel in
                                 let uu____2131 =
                                   let uu____2134 =
                                     FStar_Util.string_of_int
                                       settings.query_ifuel in
                                   let uu____2135 =
                                     let uu____2138 =
                                       FStar_Util.string_of_int
                                         settings.query_rlimit in
                                     [uu____2138; stats] in
                                   uu____2134 :: uu____2135 in
                                 uu____2130 :: uu____2131 in
                               uu____2126 :: uu____2127 in
                             used_hint_tag :: uu____2123 in
                           tag :: uu____2120 in
                         uu____2116 :: uu____2117 in
                       (settings.query_name) :: uu____2113 in
                     range :: uu____2110 in
                   FStar_Util.print
                     "%s\tQuery-stats (%s, %s)\t%s%s in %s milliseconds with fuel %s and ifuel %s and rlimit %s %s\n"
                     uu____2107);
                  FStar_All.pipe_right errs
                    (FStar_List.iter
                       (fun uu____2152  ->
                          match uu____2152 with
                          | (uu____2159,msg,range1) ->
                              let e =
                                FStar_Errors.mk_issue FStar_Errors.EInfo
                                  (FStar_Pervasives_Native.Some range1) msg in
                              let tag1 =
                                if used_hint settings
                                then "(Hint-replay failed): "
                                else "" in
                              let uu____2165 = FStar_Errors.format_issue e in
                              FStar_Util.print2 "\t\t%s%s\n" tag1 uu____2165))))
      else ()
let record_hint:
  'Auu____2175 'Auu____2176 .
    query_settings ->
      (FStar_SMTEncoding_Z3.z3status,'Auu____2176,'Auu____2175,Prims.string
                                                                 FStar_Pervasives_Native.option)
        FStar_Pervasives_Native.tuple4 -> Prims.unit
  =
  fun settings  ->
    fun z3result  ->
      let uu____2205 =
        let uu____2206 = FStar_Options.record_hints () in
        Prims.op_Negation uu____2206 in
      if uu____2205
      then ()
      else
        (let uu____2208 = z3result in
         match uu____2208 with
         | (z3status,uu____2220,z3stats,query_hash) ->
             let mk_hint core =
               {
                 FStar_Util.hint_name = (settings.query_name);
                 FStar_Util.hint_index = (settings.query_index);
                 FStar_Util.fuel = (settings.query_fuel);
                 FStar_Util.ifuel = (settings.query_ifuel);
                 FStar_Util.unsat_core = core;
                 FStar_Util.query_elapsed_time = (Prims.parse_int "0");
                 FStar_Util.hash =
                   (match z3status with
                    | FStar_SMTEncoding_Z3.UNSAT core1 -> query_hash
                    | uu____2243 -> FStar_Pervasives_Native.None)
               } in
             let store_hint hint =
               let uu____2248 = FStar_ST.op_Bang recorded_hints in
               match uu____2248 with
               | FStar_Pervasives_Native.Some l ->
                   FStar_ST.op_Colon_Equals recorded_hints
                     (FStar_Pervasives_Native.Some
                        (FStar_List.append l
                           [FStar_Pervasives_Native.Some hint]))
               | uu____2362 -> () in
             (match z3status with
              | FStar_SMTEncoding_Z3.UNSAT unsat_core ->
                  if used_hint settings
                  then store_hint (mk_hint settings.query_hint)
                  else store_hint (mk_hint unsat_core)
              | uu____2370 -> ()))
let process_result:
  query_settings ->
    (FStar_SMTEncoding_Z3.z3status,Prims.int,Prims.string FStar_Util.smap,
      Prims.string FStar_Pervasives_Native.option)
      FStar_Pervasives_Native.tuple4 -> errors FStar_Pervasives_Native.option
  =
  fun settings  ->
    fun result  ->
      (let uu____2408 =
         (used_hint settings) &&
           (let uu____2410 = FStar_Options.z3_refresh () in
            Prims.op_Negation uu____2410) in
       if uu____2408 then FStar_SMTEncoding_Z3.refresh () else ());
      (let errs = query_errors settings result in
       query_info settings result;
       record_hint settings result;
       detail_hint_replay settings result;
       errs)
let fold_queries:
  query_settings Prims.list ->
    (query_settings ->
       (FStar_SMTEncoding_Z3.z3result -> Prims.unit) -> Prims.unit)
      ->
      (query_settings ->
         FStar_SMTEncoding_Z3.z3result ->
           errors FStar_Pervasives_Native.option)
        -> (errors Prims.list -> Prims.unit) -> Prims.unit
  =
  fun qs  ->
    fun ask1  ->
      fun f  ->
        fun report1  ->
          let rec aux acc qs1 =
            match qs1 with
            | [] -> report1 acc
            | q::qs2 ->
                ask1 q
                  (fun res  ->
                     let uu____2512 = f q res in
                     match uu____2512 with
                     | FStar_Pervasives_Native.None  -> ()
                     | FStar_Pervasives_Native.Some errs ->
                         aux (errs :: acc) qs2) in
          aux [] qs
let ask_and_report_errors:
  FStar_TypeChecker_Env.env ->
    FStar_SMTEncoding_Term.error_labels ->
      FStar_SMTEncoding_Term.decl Prims.list ->
        FStar_SMTEncoding_Term.decl ->
          FStar_SMTEncoding_Term.decl Prims.list -> Prims.unit
  =
  fun env  ->
    fun all_labels  ->
      fun prefix1  ->
        fun query  ->
          fun suffix  ->
            FStar_SMTEncoding_Z3.giveZ3 prefix1;
            (let default_settings =
               let uu____2546 =
                 match env.FStar_TypeChecker_Env.qname_and_index with
                 | FStar_Pervasives_Native.None  ->
                     failwith "No query name set!"
                 | FStar_Pervasives_Native.Some (q,n1) ->
                     ((FStar_Ident.text_of_lid q), n1) in
               match uu____2546 with
               | (qname,index1) ->
                   let rlimit =
                     let uu____2572 = FStar_Options.z3_rlimit_factor () in
                     let uu____2573 =
                       let uu____2574 = FStar_Options.z3_rlimit () in
                       uu____2574 * (Prims.parse_int "544656") in
                     uu____2572 * uu____2573 in
                   let uu____2575 = FStar_TypeChecker_Env.get_range env in
                   let uu____2576 = FStar_Options.initial_fuel () in
                   let uu____2577 = FStar_Options.initial_ifuel () in
                   {
                     query_env = env;
                     query_decl = query;
                     query_name = qname;
                     query_index = index1;
                     query_range = uu____2575;
                     query_fuel = uu____2576;
                     query_ifuel = uu____2577;
                     query_rlimit = rlimit;
                     query_hint = FStar_Pervasives_Native.None;
                     query_errors = [];
                     query_all_labels = all_labels;
                     query_suffix = suffix;
                     query_hash = FStar_Pervasives_Native.None
                   } in
             let use_hints_setting =
               let uu____2583 = next_hint default_settings in
               match uu____2583 with
               | FStar_Pervasives_Native.Some
                   { FStar_Util.hint_name = uu____2588;
                     FStar_Util.hint_index = uu____2589; FStar_Util.fuel = i;
                     FStar_Util.ifuel = j;
                     FStar_Util.unsat_core = FStar_Pervasives_Native.Some
                       core;
                     FStar_Util.query_elapsed_time = uu____2593;
                     FStar_Util.hash = h;_}
                   ->
                   [(let uu___90_2602 = default_settings in
                     {
                       query_env = (uu___90_2602.query_env);
                       query_decl = (uu___90_2602.query_decl);
                       query_name = (uu___90_2602.query_name);
                       query_index = (uu___90_2602.query_index);
                       query_range = (uu___90_2602.query_range);
                       query_fuel = i;
                       query_ifuel = j;
                       query_rlimit = (uu___90_2602.query_rlimit);
                       query_hint = (FStar_Pervasives_Native.Some core);
                       query_errors = (uu___90_2602.query_errors);
                       query_all_labels = (uu___90_2602.query_all_labels);
                       query_suffix = (uu___90_2602.query_suffix);
                       query_hash = h
                     })]
               | uu____2605 -> [] in
             let initial_fuel_max_ifuel =
               let uu____2611 =
                 let uu____2612 = FStar_Options.max_ifuel () in
                 let uu____2613 = FStar_Options.initial_ifuel () in
                 uu____2612 > uu____2613 in
               if uu____2611
               then
                 let uu____2616 =
                   let uu___91_2617 = default_settings in
                   let uu____2618 = FStar_Options.max_ifuel () in
                   {
                     query_env = (uu___91_2617.query_env);
                     query_decl = (uu___91_2617.query_decl);
                     query_name = (uu___91_2617.query_name);
                     query_index = (uu___91_2617.query_index);
                     query_range = (uu___91_2617.query_range);
                     query_fuel = (uu___91_2617.query_fuel);
                     query_ifuel = uu____2618;
                     query_rlimit = (uu___91_2617.query_rlimit);
                     query_hint = (uu___91_2617.query_hint);
                     query_errors = (uu___91_2617.query_errors);
                     query_all_labels = (uu___91_2617.query_all_labels);
                     query_suffix = (uu___91_2617.query_suffix);
                     query_hash = (uu___91_2617.query_hash)
                   } in
                 [uu____2616]
               else [] in
             let half_max_fuel_max_ifuel =
               let uu____2623 =
                 let uu____2624 =
                   let uu____2625 = FStar_Options.max_fuel () in
                   uu____2625 / (Prims.parse_int "2") in
                 let uu____2632 = FStar_Options.initial_fuel () in
                 uu____2624 > uu____2632 in
               if uu____2623
               then
                 let uu____2635 =
                   let uu___92_2636 = default_settings in
                   let uu____2637 =
                     let uu____2638 = FStar_Options.max_fuel () in
                     uu____2638 / (Prims.parse_int "2") in
                   let uu____2645 = FStar_Options.max_ifuel () in
                   {
                     query_env = (uu___92_2636.query_env);
                     query_decl = (uu___92_2636.query_decl);
                     query_name = (uu___92_2636.query_name);
                     query_index = (uu___92_2636.query_index);
                     query_range = (uu___92_2636.query_range);
                     query_fuel = uu____2637;
                     query_ifuel = uu____2645;
                     query_rlimit = (uu___92_2636.query_rlimit);
                     query_hint = (uu___92_2636.query_hint);
                     query_errors = (uu___92_2636.query_errors);
                     query_all_labels = (uu___92_2636.query_all_labels);
                     query_suffix = (uu___92_2636.query_suffix);
                     query_hash = (uu___92_2636.query_hash)
                   } in
                 [uu____2635]
               else [] in
             let max_fuel_max_ifuel =
               let uu____2650 =
                 (let uu____2655 = FStar_Options.max_fuel () in
                  let uu____2656 = FStar_Options.initial_fuel () in
                  uu____2655 > uu____2656) &&
                   (let uu____2659 = FStar_Options.max_ifuel () in
                    let uu____2660 = FStar_Options.initial_ifuel () in
                    uu____2659 >= uu____2660) in
               if uu____2650
               then
                 let uu____2663 =
                   let uu___93_2664 = default_settings in
                   let uu____2665 = FStar_Options.max_fuel () in
                   let uu____2666 = FStar_Options.max_ifuel () in
                   {
                     query_env = (uu___93_2664.query_env);
                     query_decl = (uu___93_2664.query_decl);
                     query_name = (uu___93_2664.query_name);
                     query_index = (uu___93_2664.query_index);
                     query_range = (uu___93_2664.query_range);
                     query_fuel = uu____2665;
                     query_ifuel = uu____2666;
                     query_rlimit = (uu___93_2664.query_rlimit);
                     query_hint = (uu___93_2664.query_hint);
                     query_errors = (uu___93_2664.query_errors);
                     query_all_labels = (uu___93_2664.query_all_labels);
                     query_suffix = (uu___93_2664.query_suffix);
                     query_hash = (uu___93_2664.query_hash)
                   } in
                 [uu____2663]
               else [] in
             let min_fuel1 =
               let uu____2671 =
                 let uu____2672 = FStar_Options.min_fuel () in
                 let uu____2673 = FStar_Options.initial_fuel () in
                 uu____2672 < uu____2673 in
               if uu____2671
               then
                 let uu____2676 =
                   let uu___94_2677 = default_settings in
                   let uu____2678 = FStar_Options.min_fuel () in
                   {
                     query_env = (uu___94_2677.query_env);
                     query_decl = (uu___94_2677.query_decl);
                     query_name = (uu___94_2677.query_name);
                     query_index = (uu___94_2677.query_index);
                     query_range = (uu___94_2677.query_range);
                     query_fuel = uu____2678;
                     query_ifuel = (Prims.parse_int "1");
                     query_rlimit = (uu___94_2677.query_rlimit);
                     query_hint = (uu___94_2677.query_hint);
                     query_errors = (uu___94_2677.query_errors);
                     query_all_labels = (uu___94_2677.query_all_labels);
                     query_suffix = (uu___94_2677.query_suffix);
                     query_hash = (uu___94_2677.query_hash)
                   } in
                 [uu____2676]
               else [] in
             let all_configs =
               FStar_List.append use_hints_setting
                 (FStar_List.append [default_settings]
                    (FStar_List.append initial_fuel_max_ifuel
                       (FStar_List.append half_max_fuel_max_ifuel
                          max_fuel_max_ifuel))) in
             let check_one_config config k =
               (let uu____2696 =
                  (used_hint config) || (FStar_Options.z3_refresh ()) in
                if uu____2696 then FStar_SMTEncoding_Z3.refresh () else ());
               (let uu____2698 = with_fuel_and_diagnostics config [] in
                let uu____2701 =
                  let uu____2704 = FStar_SMTEncoding_Z3.mk_fresh_scope () in
                  FStar_Pervasives_Native.Some uu____2704 in
                FStar_SMTEncoding_Z3.ask
                  (filter_assertions config.query_env config.query_hint)
                  ((config.query_hash), (config.query_hint))
                  config.query_all_labels uu____2698 uu____2701 k) in
             let check_all_configs configs =
               let report1 errs =
                 report_errors
                   (let uu___95_2725 = default_settings in
                    {
                      query_env = (uu___95_2725.query_env);
                      query_decl = (uu___95_2725.query_decl);
                      query_name = (uu___95_2725.query_name);
                      query_index = (uu___95_2725.query_index);
                      query_range = (uu___95_2725.query_range);
                      query_fuel = (uu___95_2725.query_fuel);
                      query_ifuel = (uu___95_2725.query_ifuel);
                      query_rlimit = (uu___95_2725.query_rlimit);
                      query_hint = (uu___95_2725.query_hint);
                      query_errors = errs;
                      query_all_labels = (uu___95_2725.query_all_labels);
                      query_suffix = (uu___95_2725.query_suffix);
                      query_hash = (uu___95_2725.query_hash)
                    }) in
               fold_queries configs check_one_config process_result report1 in
             let uu____2726 =
               let uu____2733 = FStar_Options.admit_smt_queries () in
               let uu____2734 = FStar_Options.admit_except () in
               (uu____2733, uu____2734) in
             match uu____2726 with
             | (true ,uu____2739) -> ()
             | (false ,FStar_Pervasives_Native.None ) ->
                 check_all_configs all_configs
             | (false ,FStar_Pervasives_Native.Some id) ->
                 let skip =
                   if FStar_Util.starts_with id "("
                   then
                     let full_query_id =
                       let uu____2751 =
                         let uu____2752 =
                           let uu____2753 =
                             let uu____2754 =
                               FStar_Util.string_of_int
                                 default_settings.query_index in
                             Prims.strcat uu____2754 ")" in
                           Prims.strcat ", " uu____2753 in
                         Prims.strcat default_settings.query_name uu____2752 in
                       Prims.strcat "(" uu____2751 in
                     full_query_id <> id
                   else default_settings.query_name <> id in
                 if Prims.op_Negation skip
                 then check_all_configs all_configs
                 else ())
let solve:
  (Prims.unit -> Prims.string) FStar_Pervasives_Native.option ->
    FStar_TypeChecker_Env.env -> FStar_Syntax_Syntax.term -> Prims.unit
  =
  fun use_env_msg  ->
    fun tcenv  ->
      fun q  ->
        (let uu____2779 =
           let uu____2780 =
             let uu____2781 = FStar_TypeChecker_Env.get_range tcenv in
             FStar_All.pipe_left FStar_Range.string_of_range uu____2781 in
           FStar_Util.format1 "Starting query at %s" uu____2780 in
         FStar_SMTEncoding_Encode.push uu____2779);
        (let tcenv1 = FStar_TypeChecker_Env.incr_query_index tcenv in
         let uu____2783 =
           FStar_SMTEncoding_Encode.encode_query use_env_msg tcenv1 q in
         match uu____2783 with
         | (prefix1,labels,qry,suffix) ->
             let pop1 uu____2817 =
               let uu____2818 =
                 let uu____2819 =
                   let uu____2820 = FStar_TypeChecker_Env.get_range tcenv1 in
                   FStar_All.pipe_left FStar_Range.string_of_range uu____2820 in
                 FStar_Util.format1 "Ending query at %s" uu____2819 in
               FStar_SMTEncoding_Encode.pop uu____2818 in
             (match qry with
              | FStar_SMTEncoding_Term.Assume
                  {
                    FStar_SMTEncoding_Term.assumption_term =
                      {
                        FStar_SMTEncoding_Term.tm =
                          FStar_SMTEncoding_Term.App
                          (FStar_SMTEncoding_Term.FalseOp ,uu____2821);
                        FStar_SMTEncoding_Term.freevars = uu____2822;
                        FStar_SMTEncoding_Term.rng = uu____2823;_};
                    FStar_SMTEncoding_Term.assumption_caption = uu____2824;
                    FStar_SMTEncoding_Term.assumption_name = uu____2825;
                    FStar_SMTEncoding_Term.assumption_fact_ids = uu____2826;_}
                  -> pop1 ()
              | uu____2841 when tcenv1.FStar_TypeChecker_Env.admit -> pop1 ()
              | FStar_SMTEncoding_Term.Assume uu____2842 ->
                  (ask_and_report_errors tcenv1 labels prefix1 qry suffix;
                   pop1 ())
              | uu____2844 -> failwith "Impossible"))
let solver: FStar_TypeChecker_Env.solver_t =
  {
    FStar_TypeChecker_Env.init = FStar_SMTEncoding_Encode.init;
    FStar_TypeChecker_Env.push = FStar_SMTEncoding_Encode.push;
    FStar_TypeChecker_Env.pop = FStar_SMTEncoding_Encode.pop;
    FStar_TypeChecker_Env.encode_modul =
      FStar_SMTEncoding_Encode.encode_modul;
    FStar_TypeChecker_Env.encode_sig = FStar_SMTEncoding_Encode.encode_sig;
    FStar_TypeChecker_Env.preprocess =
      (fun e  ->
         fun g  ->
           let uu____2850 =
             let uu____2857 = FStar_Options.peek () in (e, g, uu____2857) in
           [uu____2850]);
    FStar_TypeChecker_Env.solve = solve;
    FStar_TypeChecker_Env.is_trivial = FStar_SMTEncoding_Encode.is_trivial;
    FStar_TypeChecker_Env.finish = FStar_SMTEncoding_Z3.finish;
    FStar_TypeChecker_Env.refresh = FStar_SMTEncoding_Z3.refresh
  }
let dummy: FStar_TypeChecker_Env.solver_t =
  {
    FStar_TypeChecker_Env.init = (fun uu____2872  -> ());
    FStar_TypeChecker_Env.push = (fun uu____2874  -> ());
    FStar_TypeChecker_Env.pop = (fun uu____2876  -> ());
    FStar_TypeChecker_Env.encode_modul =
      (fun uu____2879  -> fun uu____2880  -> ());
    FStar_TypeChecker_Env.encode_sig =
      (fun uu____2883  -> fun uu____2884  -> ());
    FStar_TypeChecker_Env.preprocess =
      (fun e  ->
         fun g  ->
           let uu____2890 =
             let uu____2897 = FStar_Options.peek () in (e, g, uu____2897) in
           [uu____2890]);
    FStar_TypeChecker_Env.solve =
      (fun uu____2913  -> fun uu____2914  -> fun uu____2915  -> ());
    FStar_TypeChecker_Env.is_trivial =
      (fun uu____2922  -> fun uu____2923  -> false);
    FStar_TypeChecker_Env.finish = (fun uu____2925  -> ());
    FStar_TypeChecker_Env.refresh = (fun uu____2927  -> ())
  }