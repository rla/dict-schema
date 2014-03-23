:- begin_tests(dict_schema).

:- use_module(prolog/dict_schema).

test(valid_string):-
    convert("abc", _{ type: string }, "abc", []).

test(valid_string_atom):-
    convert(abc, _{ type: string }, "abc", []).

test(invalid_string):-
    convert(1, _{ type: string }, 1, [not_string('#', 1)]).

test(valid_max_length_string):-
    convert("abc", _{ type: string, max_length: 3 }, "abc", []).

test(invalid_max_length_string):-
    convert("abc", _{ type: string, max_length: 2 }, "abc", [max_length('#', "abc", 2)]).

test(valid_min_length_string):-
    convert("abc", _{ type: string, min_length: 3 }, "abc", []).

test(invalid_min_length_string):-
    convert("abc", _{ type: string, min_length: 4 }, "abc", [min_length('#', "abc", 4)]).

test(valid_atom):-
    convert(abc, _{ type: atom }, abc, []).

test(valid_atom_string):-
    convert("abc", _{ type: atom }, abc, []).

test(invalid_atom):-
    convert(1, _{ type: atom }, 1, [not_atom('#', 1)]).

test(valid_max_length_atom):-
    convert(abc, _{ type: atom, max_length: 3 }, abc, []).

test(invalid_max_length_atom):-
    convert(abc, _{ type: atom, max_length: 2 }, abc, [max_length('#', abc, 2)]).

test(valid_min_length_atom):-
    convert(abc, _{ type: atom, min_length: 3 }, abc, []).

test(invalid_min_length_atom):-
    convert(abc, _{ type: atom, min_length: 4 }, abc, [min_length('#', abc, 4)]).

test(valid_number):-
    convert(123, _{ type: number }, 123, []).

test(valid_number_float):-
    convert(123.45, _{ type: number }, 123.45, []).

test(invalid_number):-
    convert(abc, _{ type: number }, abc, [not_number('#', abc)]).

test(valid_number_min):-
    convert(123, _{ type: number, min: 123 }, 123, []).

test(invalid_number_min):-
    convert(123, _{ type: number, min: 124 }, 123, [min('#', 123, 124)]).

test(valid_number_max):-
    convert(123, _{ type: number, max: 123 }, 123, []).

test(invalid_number_max):-
    convert(123, _{ type: number, max: 122 }, 123, [max('#', 123, 122)]).

test(valid_integer):-
    convert(123, _{ type: integer }, 123, []).

test(invalid_integer_float):-
    convert(123.45, _{ type: integer }, 123.45, [not_integer('#', 123.45)]).

test(invalid_integer):-
    convert(abc, _{ type: integer }, abc, [not_integer('#', abc)]).

test(valid_integer_min):-
    convert(123, _{ type: integer, min: 123 }, 123, []).

test(invalid_integer_min):-
    convert(123, _{ type: integer, min: 124 }, 123, [min('#', 123, 124)]).

test(valid_integer_max):-
    convert(123, _{ type: integer, max: 123 }, 123, []).

test(invalid_integer_max):-
    convert(123, _{ type: integer, max: 122 }, 123, [max('#', 123, 122)]).

test(valid_enum):-
    convert(bar, _{ type: enum, values: [ foo, bar ] }, bar, []).

test(valid_enum_string):-
    convert("bar", _{ type: enum, values: [ foo, bar ] }, bar, []).

test(invalid_enum):-
    convert(baz, _{ type: enum, values: [ foo, bar ] }, baz, [invalid_enum_value('#', baz)]).

test(invalid_enum):-
    convert(1, _{ type: enum, values: [ foo, bar ] }, 1, [invalid_enum_value('#', 1)]).

test(valid_dict_1):-
    convert(t{ a: 1 }, _{ type: dict, keys: _{ a: _{ type: integer } } },
        t{ a: 1 }, []).

test(valid_dict_2):-
    convert(T{ a: 1 }, _{ type: dict, keys: _{ a: _{ type: integer } } },
        T{ a: 1 }, []).

test(valid_dict_3):-
    convert(t{ a: 1 }, _{ type: dict, tag: t, keys: _{ a: _{ type: integer } } },
        t{ a: 1 }, []).

test(valid_dict_4):-
    convert(_{ a: 1 }, _{ type: dict, tag: t, keys: _{ a: _{ type: integer } } },
        t{ a: 1 }, []).

test(invalid_dict_tag):-
    convert(t1{ a: 1 }, _{ type: dict, tag: t2, keys: _{ a: _{ type: integer } } },
        t1{ a: 1 }, [invalid_tag('#', t1, t2)]).

test(invalid_dict_missing_key):-
    convert(t{ b: 1 }, _{ type: dict, tag: t, keys: _{ a: _{ type: integer } } },
        _, [no_key(('#')/a)]).

test(dict_drop_extra_key):-
    convert(t{ a: 1, b: 2 }, _{ type: dict, tag: t, keys: _{ a: _{ type: integer } } },
        t{ a: 1 }, []).

% FIXME test optional keys.

test(valid_empty_list):-
    convert([], _{ type: list, items: _{ type: number } }, [], []).

test(valid_list_1):-
    convert([1], _{ type: list, items: _{ type: number } }, [1], []).

test(valid_list_2):-
    convert([1, 2], _{ type: list, items: _{ type: number } }, [1, 2], []).

test(invalid_list_item):-
    convert([1, a], _{ type: list, items: _{ type: number } },
        [1, a], [not_number(('#')/[1],a)]).

test(valid_list_length):-
    convert([1], _{ type: list, items: _{ type: number },
        min_length: 1, max_length: 1 }, [1], []).

test(invalid_list_min_length):-
    convert([1], _{ type: list, items: _{ type: number },
        min_length: 2 }, [1], [min_length('#', [1], 2)]).

test(invalid_list_max_length):-
    convert([1, 2], _{ type: list, items: _{ type: number },
        max_length: 1 }, [1, 2], [max_length('#', [1, 2], 1)]).

test(valid_compound):-
    convert(f(1), _{ type: compound, name: f, arguments: [ _{ type: number } ] },
        f(1), []).

test(invalid_compound):-
    convert(1, _{ type: compound, name: f, arguments: [ _{ type: number } ] },
        1, [invalid_compound('#', 1)]).

test(invalid_compound_arg):-
    convert(f(a), _{ type: compound, name: f, arguments: [ _{ type: number } ] },
        f(a), [not_number(('#')/f(0), a)]).

test(invalid_compound_name):-
    convert(g(1), _{ type: compound, name: f, arguments: [ _{ type: number } ] },
        g(1), [compound_name('#',f,g)]).

test(any):-
    convert(a, _{ type: any }, a, []).

test(named, [ setup(register_schema(test, _{ type: number })),
    cleanup(unregister_schema(test))]):-
    convert(1, test, 1, []).

:- register_schema(node, _{
    type: dict,
    tag: node,
    keys: _{
        data: any,
        left: node,
        right: node
    },
    optional: [ left, right ]
}).

test(tree):-
    convert(_{ data: 123, left: _{ data: 345 } }, node,
        node{ data:123, left: node{ data:345 } }, []).

test(valid_union_1):-
    convert(1, [ number, atom ], 1, []).

test(valid_union_2):-
    convert(a, [ number, atom ], a, []).

:- end_tests(dict_schema).
