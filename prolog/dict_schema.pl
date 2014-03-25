:- module(dict_schema, [
    convert/4,          % +In, +Schema, -Out, -Errors
    register_schema/2,  % +Name, +Schema
    unregister_schema/1 % +Name
]).

/** <module> Dict validation and conversion

Converts string to atoms and vice versa. Validates
your dicts. See the project's README file for examples.
*/

:- use_module(library(error)).

:- dynamic(schema/2).

%! register_schema(+Name, +Schema) is det.
%
% Registers a named schema. The existing schema
% with the same name is replaced.

register_schema(Name, Schema):-
    must_be(atom, Name),
    retractall(schema(Name, _)),
    assertz(schema(Name, Schema)).

%! unregister_schema(+Name) is det.
%
% Unregisters the given named schema. Does
% nothing when the schema does not exist.

unregister_schema(Name):-
    retractall(schema(Name)).

%! convert(+In, +Schema, -Out, -Errors) is det.
%
% Checks/converts the input value according to the schema.
% Errors contains the errors occurred during the
% check/conversion process. When Schema is atom,
% the named schema will be used.

convert(In, Schema, Out, Errors):-
    convert('#', Schema, In, Out, [], Errors).

convert(Path, string, In, Out, EIn, EOut):- !,
    convert(Path, _{ type: string }, In, Out, EIn, EOut).

convert(Path, atom, In, Out, EIn, EOut):- !,
    convert(Path, _{ type: atom }, In, Out, EIn, EOut).

convert(Path, number, In, Out, EIn, EOut):- !,
    convert(Path, _{ type: number }, In, Out, EIn, EOut).

convert(Path, integer, In, Out, EIn, EOut):- !,
    convert(Path, _{ type: integer }, In, Out, EIn, EOut).

convert(Path, any, In, Out, EIn, EOut):- !,
    convert(Path, _{ type: any }, In, Out, EIn, EOut).

convert(Path, var, In, Out, EIn, EOut):- !,
    convert(Path, _{ type: var }, In, Out, EIn, EOut).

convert(Path, bool, In, Out, EIn, EOut):- !,
    convert(Path, _{ type: bool }, In, Out, EIn, EOut).

convert(Path, Name, In, Out, EIn, EOut):-
    atom(Name), !,
    (   schema(Name, Schema)
    ->  convert(Path, Schema, In, Out, EIn, EOut)
    ;   throw(error(no_schema(Path, Name)))).

convert(Path, Union, In, Out, EIn, EOut):-
    is_list(Union), !,
    convert_union(Union, Path, In, Out, [], EIn, EOut).

convert(Path, Schema, In, Out, EIn, EOut):-
    get_dict_ex(type, Schema, Type),
    convert_type(Type, Path, Schema, In, Out, EIn, EOut).

convert_type(dict, Path, Schema, In, Out, EIn, EOut):- !,
    validate_dict_schema(Path, Schema),
    convert_dict(Path, Schema, In, Out, EIn, EOut).

convert_type(string, Path, Schema, In, Out, EIn, EOut):- !,
    validate_string_schema(Path, Schema),
    convert_string(Path, Schema, In, Out, EIn, EOut).

convert_type(atom, Path, Schema, In, Out, EIn, EOut):- !,
    validate_atom_schema(Path, Schema),
    convert_atom(Path, Schema, In, Out, EIn, EOut).

convert_type(enum, Path, Schema, In, Out, EIn, EOut):- !,
    validate_enum_schema(Path, Schema),
    convert_enum(Path, Schema, In, Out, EIn, EOut).

convert_type(integer, Path, Schema, In, Out, EIn, EOut):- !,
    validate_integer_schema(Path, Schema),
    convert_integer(Path, Schema, In, Out, EIn, EOut).

convert_type(number, Path, Schema, In, Out, EIn, EOut):- !,
    validate_number_schema(Path, Schema),
    convert_number(Path, Schema, In, Out, EIn, EOut).

convert_type(list, Path, Schema, In, Out, EIn, EOut):- !,
    validate_list_schema(Path, Schema),
    convert_list(Path, Schema, In, Out, EIn, EOut).

convert_type(compound, Path, Schema, In, Out, EIn, EOut):- !,
    validate_compound_schema(Path, Schema),
    convert_compound(Path, Schema, In, Out, EIn, EOut).

convert_type(any, Path, Schema, In, In, EIn, EIn):- !,
    check_is_dict(Path, Schema),
    allowed_attributes(any, Path, Schema, []).

convert_type(var, Path, Schema, In, In, EIn, EOut):- !,
    check_is_dict(Path, Schema),
    allowed_attributes(var, Path, Schema, []),
    (   var(In)
    ;   EOut = [not_variable(Path, In)|EIn]), !.

convert_type(bool, Path, Schema, In, Out, EIn, EOut):- !,
    check_is_dict(Path, Schema),
    allowed_attributes(bool, Path, Schema, []),
    convert_bool(Path, In, Out, EIn, EOut).

convert_type(Type, Path, _, _, _, _, _):-
    throw(error(unknown_type(Path, Type))).

% Tries to match one of the schemas in union.

convert_union([Schema|Schemas], Path, In, Out, EReasons, EIn, EOut):-
    convert(Path, Schema, In, Out, [], ETmp),
    (   (
            ETmp = [],
            EOut = EIn)
    ;   convert_union(Schemas, Path, In, Out, [ETmp|EReasons], EIn, EOut)), !.

convert_union([], Path, In, In, EReasons, EIn, EOut):-
    EOut = [union_mismatch(Path, EReasons)|EIn].

% Schema "metavalidation" code.
% Checks for allowed attributes.

validate_dict_schema(Path, Schema):-
    check_is_dict(Path, Schema),
    allowed_attributes(dict, Path, Schema, [tag, keys, optional, additional]),
    (   get_dict(keys, Schema, _)
    ->  true
    ;   throw(error(dict_no_keys(Path, Schema)))).

validate_string_schema(Path, Schema):-
    check_is_dict(Path, Schema),
    allowed_attributes(string, Path, Schema, [min_length, max_length]).

validate_atom_schema(Path, Schema):-
    check_is_dict(Path, Schema),
    allowed_attributes(atom, Path, Schema, [min_length, max_length]).

validate_enum_schema(Path, Schema):-
    check_is_dict(Path, Schema),
    allowed_attributes(atom, Path, Schema, [values]),
    (   get_dict(values, Schema, Values)
    ->  validate_enum_values(Values, Path)
    ;   throw(error(enum_no_values(Path, Schema)))).

validate_integer_schema(Path, Schema):-
    check_is_dict(Path, Schema),
    allowed_attributes(integer, Path, Schema, [min, max]).

validate_number_schema(Path, Schema):-
    check_is_dict(Path, Schema),
    allowed_attributes(number, Path, Schema, [min, max]).

validate_list_schema(Path, Schema):-
    check_is_dict(Path, Schema),
    allowed_attributes(number, Path, Schema, [items, min_length, max_length]),
    (   get_dict(items, Schema, _)
    ->  true
    ;   throw(error(missing_item_schema(Path, Schema)))).

validate_compound_schema(Path, Schema):-
    check_is_dict(Path, Schema),
    allowed_attributes(compound, Path, Schema, [name, arguments]),
    (   get_dict(name, Schema, _)
    ->  true
    ;   throw(error(missing_compound_name(Path, Schema)))),
    (   get_dict(arguments, Schema, _)
    ->  true
    ;   throw(error(missing_compound_arguments(Path, Schema)))).

validate_enum_values([Value|Values], Path):-
    (   atom(Value)
    ->  validate_enum_values(Values, Path)
    ;   throw(error(invalid_enum_value(Path, Value)))).

validate_enum_values([], _).

allowed_attributes(Type, Path, Schema, Allowed):-
    dict_pairs(Schema, _, Pairs),
    check_attributes(Pairs, Path, Type, [type|Allowed]).

check_attributes([Key-_|Pairs], Path, Type, Allowed):-
    (   memberchk(Key, Allowed)
    ->  check_attributes(Pairs, Path, Type, Allowed)
    ;   throw(error(invalid_type_attribute(Path, Key, Type)))).

check_attributes([], _, _, _).

check_is_dict(Path, Schema):-
    (   is_dict(Schema)
    ->  true
    ;   throw(error(schema_not_dict(Path, Schema)))).

% Checks bool true/false.

convert_bool(Path, In, In, EIn, EOut):-
    var(In), !,
    EOut = [not_ground(Path, In)|EIn].

convert_bool(Path, In, In, EIn, EOut):-
    (   (In = true ; In = false)
    ->  EOut = EIn
    ;   EOut = [not_bool(Path, In)]).

% Converts list.

convert_list(Path, _, In, In, EIn, EOut):-
    var(In), !,
    EOut = [not_ground(Path, In)|EIn].

convert_list(Path, Schema, In, Out, EIn, EOut):-
    is_list(In), !,
    get_dict_ex(items, Schema, ItemSchema),
    convert_list(In, Path, 0, ItemSchema, Out, EIn, ETmp),
    validate_list(Path, Schema, Out, ETmp, EOut).

convert_list(Path, _, In, In, EIn, EOut):-
    EOut = [not_list(Path, In)|EIn].

convert_list([In|Ins], Path, N, ItemSchema, [Out|Outs], EIn, EOut):-
    convert(Path/[N], ItemSchema, In, Out, EIn, ETmp),
    N1 is N + 1,
    convert_list(Ins, Path, N1, ItemSchema, Outs, ETmp, EOut).

convert_list([], _, _, _, [], EIn, EIn).

% Checks list min/max length.

validate_list(Path, Schema, List, EIn, EOut):-
    validate_list_min_length(Path, Schema, List, EIn, ETmp),
    validate_list_max_length(Path, Schema, List, ETmp, EOut).

validate_list_min_length(Path, Schema, List, EIn, EOut):-
    (   get_dict(min_length, Schema, MinLength)
    ->  (   length(List, Length),
            Length < MinLength
        ->  EOut = [min_length(Path, List, MinLength)|EIn]
        ;   EOut = EIn)
    ;   EOut = EIn).

validate_list_max_length(Path, Schema, List, EIn, EOut):-
    (   get_dict(max_length, Schema, MaxLength)
    ->  (   length(List, Length),
            Length > MaxLength
        ->  EOut = [max_length(Path, List, MaxLength)|EIn]
        ;   EOut = EIn)
    ;   EOut = EIn).

% Converts dict.

convert_dict(Path, _, In, In, EIn, EOut):-
    var(In), !,
    EOut = [not_ground(Path, In)|EIn].

convert_dict(Path, Schema, In, Out, EIn, EOut):-
    is_dict(In, Tag), !,
    convert_dict(Tag, Path, Schema, In, Out, EIn, EOut).

convert_dict(Path, _, In, In, EIn, EOut):-
    EOut = [not_dict(Path, In)|EIn].

convert_dict(Tag, Path, Schema, In, Out, EIn, EOut):-
    (   get_dict(optional, Schema, Optional)
    ;   Optional = []), !,
    (   get_dict(tag, Schema, SchemaTag)
    ->  (   Tag = SchemaTag
        ->  get_dict_ex(keys, Schema, Keys),
            dict_pairs(Keys, _, Pairs),
            convert_keys(Pairs, Optional, Path, In, OutPairs, EIn, ETmp),
            dict_pairs(Out, Tag, OutPairs),
            validate_additional(Path, In, Schema, ETmp, EOut)
        ;   Out = In,
            EOut = [invalid_tag(Path, Tag, SchemaTag)|EIn])
    ;   get_dict_ex(keys, Schema, Keys),
        dict_pairs(Keys, _, Pairs),
        convert_keys(Pairs, Optional, Path, In, OutPairs, EIn, ETmp),
        dict_pairs(Out, Tag, OutPairs),
        validate_additional(Path, In, Schema, ETmp, EOut)).

convert_keys([Key-Schema|Pairs], Optional, Path, In, OutPairs, EIn, EOut):-
    (   get_dict(Key, In, Value)
    ->  convert(Path/Key, Schema, Value, Out, EIn, ETmp),
        OutPairs = [Key-Out|OutPairsRest],
        convert_keys(Pairs, Optional, Path, In, OutPairsRest, ETmp, EOut)
    ;   (   memberchk(Key, Optional)
        ->  ETmp = EIn
        ;   ETmp = [no_key(Path, Key)|EIn]),
        convert_keys(Pairs, Optional, Path, In, OutPairs, ETmp, EOut)).

convert_keys([], _, _, _, [], Errors, Errors).

% Checks that no additional keys are
% present in dict with additional: false.

validate_additional(_, _, Schema, EIn, EIn):-
    get_dict(additional, Schema, true), !.

validate_additional(Path, In, Schema, EIn, EOut):-
    dict_pairs(In, _, Pairs),
    get_dict(keys, Schema, Keys),
    validate_additional_keys(Pairs, Path, Keys, EIn, EOut).

validate_additional_keys([Key-_|Pairs], Path, Keys, EIn, EOut):-
    (   get_dict(Key, Keys, _)
    ->  validate_additional_keys(Pairs, Path, Keys, EIn, EOut)
    ;   ETmp = [additional_key(Path, Key)|EIn],
        validate_additional_keys(Pairs, Path, Keys, ETmp, EOut)).

validate_additional_keys([], _, _, EIn, EIn).

% Converts string.

convert_string(Path, _, In, In, EIn, EOut):-
    var(In), !,
    EOut = [not_ground(Path, In)|EIn].

convert_string(Path, Schema, In, In, EIn, EOut):-
    string(In), !,
    validate_string(Path, Schema, In, EIn, EOut).

convert_string(Path, Schema, In, Out, EIn, EOut):-
    atom(In), !,
    atom_string(In, Out),
    validate_string(Path, Schema, Out, EIn, EOut).

convert_string(Path, _, In, In, EIn, EOut):-
    EOut = [not_string(Path, In)|EIn].

% Validates string min/max length.

validate_string(Path, Schema, String, EIn, EOut):-
    validate_string_min_length(Path, Schema, String, EIn, ETmp),
    validate_string_max_length(Path, Schema, String, ETmp, EOut).

validate_string_min_length(Path, Schema, String, EIn, EOut):-
    (   get_dict(min_length, Schema, MinLength)
    ->  (   string_length(String, Length),
            Length < MinLength
        ->  EOut = [min_length(Path, String, MinLength)|EIn]
        ;   EOut = EIn)
    ;   EOut = EIn).

validate_string_max_length(Path, Schema, String, EIn, EOut):-
    (   get_dict(max_length, Schema, MaxLength)
    ->  (   string_length(String, Length),
            Length > MaxLength
        ->  EOut = [max_length(Path, String, MaxLength)|EIn]
        ;   EOut = EIn)
    ;   EOut = EIn).

% Converts atom.

convert_atom(Path, _, In, In, EIn, EOut):-
    var(In), !,
    EOut = [not_ground(Path, In)|EIn].

convert_atom(Path, Schema, In, In, EIn, EOut):-
    atom(In), !,
    validate_atom(Path, Schema, In, EIn, EOut).

convert_atom(Path, Schema, In, Out, EIn, EOut):-
    string(In), !,
    atom_string(Out, In),
    validate_atom(Path, Schema, Out, EIn, EOut).

convert_atom(Path, _, In, In, EIn, EOut):-
    EOut = [not_atom(Path, In)|EIn].

% Validates atom min/max length.

validate_atom(Path, Schema, Atom, EIn, EOut):-
    validate_atom_min_length(Path, Schema, Atom, EIn, ETmp),
    validate_atom_max_length(Path, Schema, Atom, ETmp, EOut).

validate_atom_min_length(Path, Schema, Atom, EIn, EOut):-
    (   get_dict(min_length, Schema, MinLength)
    ->  (   atom_length(Atom, Length),
            Length < MinLength
        ->  EOut = [min_length(Path, Atom, MinLength)|EIn]
        ;   EOut = EIn)
    ;   EOut = EIn).

validate_atom_max_length(Path, Schema, Atom, EIn, EOut):-
    (   get_dict(max_length, Schema, MaxLength)
    ->  (   atom_length(Atom, Length),
            Length > MaxLength
        ->  EOut = [max_length(Path, Atom, MaxLength)|EIn]
        ;   EOut = EIn)
    ;   EOut = EIn).

% Checks integer.

convert_integer(Path, _, In, In, EIn, EOut):-
    var(In), !,
    EOut = [not_ground(Path, In)|EIn].

convert_integer(Path, Schema, In, In, EIn, EOut):-
    integer(In), !,
    validate_integer(Path, Schema, In, EIn, EOut).

convert_integer(Path, _, In, In, EIn, EOut):-
    EOut = [not_integer(Path, In)|EIn].

% Checks min/max bounds of integer.

validate_integer(Path, Schema, Int, EIn, EOut):-
    validate_number_min(Path, Schema, Int, EIn, ETmp),
    validate_number_max(Path, Schema, Int, ETmp, EOut).

validate_number_min(Path, Schema, Num, EIn, EOut):-
    (   get_dict(min, Schema, Min)
    ->  (   Num < Min
        ->  EOut = [min(Path, Num, Min)|EIn]
        ;   EOut = EIn)
    ;   EOut = EIn).

validate_number_max(Path, Schema, Num, EIn, EOut):-
    (   get_dict(max, Schema, Max)
    ->  (   Num > Max
        ->  EOut = [max(Path, Num, Max)|EIn]
        ;   EOut = EIn)
    ;   EOut = EIn).

% Checks number.

convert_number(Path, _, In, In, EIn, EOut):-
    var(In), !,
    EOut = [not_ground(Path, In)|EIn].

convert_number(Path, Schema, In, In, EIn, EOut):-
    number(In), !,
    validate_number(Path, Schema, In, EIn, EOut).

convert_number(Path, _, In, In, EIn, EOut):-
    EOut = [not_number(Path, In)|EIn].

% Checks min/max bounds of number.

validate_number(Path, Schema, Num, EIn, EOut):-
    validate_number_min(Path, Schema, Num, EIn, ETmp),
    validate_number_max(Path, Schema, Num, ETmp, EOut).

% Converts/checks enum.

convert_enum(Path, _, In, In, EIn, EOut):-
    var(In), !,
    EOut = [not_ground(Path, In)|EIn].

convert_enum(Path, Schema, In, In, EIn, EOut):-
    atom(In), !,
    get_dict_ex(values, Schema, Values),
    check_enum(Path, Values, In, EIn, EOut).

convert_enum(Path, Schema, In, Out, EIn, EOut):-
    string(In), !,
    atom_string(Out, In),
    get_dict_ex(values, Schema, Values),
    check_enum(Path, Values, Out, EIn, EOut).

convert_enum(Path, _, In, In, EIn, EOut):-
    EOut = [invalid_enum_value(Path, In)|EIn].

check_enum(_, Values, In, EIn, EIn):-
    memberchk(In, Values), !.

check_enum(Path, _, In, EIn, EOut):-
    EOut = [invalid_enum_value(Path, In)|EIn].

% Converts/checks compound.

convert_compound(Path, _, In, In, EIn, EOut):-
    var(In), !,
    EOut = [not_ground(Path, In)|EIn].

convert_compound(Path, Schema, In, Out, EIn, EOut):-
    compound(In), !,
    get_dict_ex(name, Schema, Name),
    get_dict_ex(arguments, Schema, ArgSchemas),
    In =.. [ActualName|ActualArgs],
    (   Name = ActualName
    ->  length(ArgSchemas, ArgSchemasLen),
        length(ActualArgs, ActualLen),
        (   ArgSchemasLen = ActualLen
        ->  length(ConvertedArgs, ArgSchemasLen),
            Out =.. [Name|ConvertedArgs],
            convert_compound_args(ActualArgs, ArgSchemas, Name, 0, Path, ConvertedArgs, EIn, EOut)
        ;   EOut = [compound_args_length(Path, ActualLen, ArgSchemasLen)|EIn])
    ;   EOut = [compound_name(Path, ActualName, Name)|EIn]).

convert_compound(Path, _, In, In, EIn, EOut):-
    EOut = [invalid_compound(Path, In)|EIn].

convert_compound_args([Actual|ActualArgs], [Schema|ArgSchemas], Name, N, Path, [Converted|ConvertedArgs], EIn, EOut):-
    ArgPath =.. [Name, N],
    convert(Path/ArgPath, Schema, Actual, Converted, EIn, ETmp),
    N1 is N + 1,
    convert_compound_args(ActualArgs, ArgSchemas, Name, N1, Path, ConvertedArgs, ETmp, EOut).

convert_compound_args([], _, _, _, _, _, EIn, EIn).
