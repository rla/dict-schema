# dict-schema

Dict validation/conversion for Swi-Prolog. The library started as a predicate
to convert certain dict (from HTTP JSON requests) entries into suitable forms
(especially the string/atom conversion). A large part of this library was inspired
by JSON-Schema.

## Example

Check vehicle against a schema:

    ?- Schema = _{
        type: dict,
        keys: _{
            year: _{
                type: integer,
                min: 1672
            },
            make: _{
                type: atom,
                min_length: 1
            },
            model: _{
                type: atom,
                min_length: 1
            }
        }
    },
    Vehicle = vehicle{
        year: 1953,
        make: chevrolet,
        model: corvette
    },
    convert(Vehicle, Schema, Out, Errors),
    Out = vehicle{make:chevrolet, model:corvette, year:1953},
    Errors = [].

You can name the schema by registering it:

    ?- register_schema(vehicle, _{
        type: dict,
        keys: _{
            year: _{
                type: integer,
                min: 1672
            },
            make: _{
                type: atom,
                min_length: 1
            },
            model: _{
                type: atom,
                min_length: 1
            }
        }
    }).

And then use it by name:

    Vehicle = vehicle{
        year: 1200,
        make: chevrolet,
        model: corvette
    },
    convert(Vehicle, vehicle, Out, Errors).
    Out = vehicle{make:chevrolet, model:corvette, year:1200},
    Errors = [min(# / year, 1200, 1672)].

The last example also shows validation error for the `year` key. Another
feature is automatic conversion from strings to atoms when the atom type
is requested:

    ?- convert("abc", atom, Out, Errors), atom(Out).

## Path indicators

Path indicators are used for locating errors in terms. They have the following
meaning:

 * `#` - the term root (or root term).
 * `key` - (an atom), key of dict.
 * `name(N)` - N-th argument of compound with the name `name`.
 * `[N]` - N-th element in the list.
 * `/` - path separators.

Example:

    ?- Schema = _{
        type: dict,
        keys: _{
            a: _{
                type: list,
                items: _{
                    type: compound,
                    name: b,
                    arguments: [ number ]
                }
            }
        }
    },
    In = d{ a: [ b(2), b(a), b(4) ] },
    convert(In, Schema, Out, Errors).
    Out = d{a:[b(2), b(a), b(4)]},
    Errors = [not_number(#/a/[1]/b(0), a)].

The error path `#/a/[1]/b(0)` refers here to the key `a` in the root dict, the 1-st item
of the list (starts from 0) and the 0-th argument of the term.

## Primitive values

### string

String type has the following optional attributes:

 * min_length - specifies the minimum length of the string.
 * max_length - specifies the maximum length of the string.

When the input value is an atom, it is converted into a string. All
other input values other than strings will produce
an error `not_string(Path, Value)`.

When the `min_length` property is violated then an
error `min_length(Path, Value, MinLength)` is produced.
When the `max_length` property is violated then an
error `max_length(Path, Value, MaxLength)` is produced.

### atom

Works similar to the `string` type. When the input is a string,
it is converted to an atom. Has same optional attributes.
When input is not a string or atom, an error
term `not_atom(Path, Value)` is produced.

### number

Number type has the following optional attributes:

 * min - specifies the minimum value of the number.
 * max - specifies the maximum value of the number.

All other values than numbers will produce an error.

When the `min` property is violated then an error term
`min(Path, Value, Min)` is produced.
When the `max` property is violated then an error term
`max(Path, Value, Max)` is produced.

### integer

Same as the type `number` but allows integers only.

### enum

The enum type has attribute `values` that contains a list of allowed values.
The list must contain atoms. If the checked value is not in the list
then an error is produced. If the input value is a string then it is converted
into an atom first. All other values produce an error.

## Composite values

### dict

The dict type has the following attributes:

 * tag - specifies the tag of the dict. When the input has unbound
   tag it will be unified with the specified tag. If the tag attribute
   is missing then no tag checking is performed.
 * keys - specifies dict keys and schemas for values.
 * optional - list of keys that are optional.

Input keys that are not in the `keys` will be dropped from the output.

### list

The list type has the following attributes:

 * items - specifies the type of the list items.
 * min_length - specifies the minimum number of items.
 * max_length - specifies the maximum number of items.

### compound

The compound type has the following attributes:

 * name - the compound name.
 * arguments - the compound arguments.

## Unions

Union of types can be expressed with using a list. The first schema and
the conversion result that matches is used. When no schema matches then
an error `no_union_match(Path, Value)` is produced.

Examples:

    ?- convert(123, [ number, atom ], Out, Errors).
    Out = 123,
    Errors = [].

    ?- convert(a(1), [ number, atom ], Out, Errors).
    Out = a(1),
    Errors = [union_mismatch(#, [
        [not_atom(#, a(1))],
        [not_number(#, a(1))]
    ])].

## Any

Type `any` marks the value non-checked and non-converted.

## Named schemas

Named schema can be added with `register_schema(Name, Schema)` and removed with
`unregister_schema(Name)`. Schema names must be atoms.

## Validating trees

Tree with positive numbers:

    ?- register_schema(tree, [
        _{
            type: compound,
            name: branch,
            arguments: [ tree, tree ]
        },
        _{
            type: integer,
            min: 0
        }
    ]).

    ?- convert(branch(32, branch(13, 56)), tree, Out, Errors).
    Out = branch(32, branch(13, 56)),
    Errors = [].

    ?- convert(branch(32, a), tree, Out, Errors).
    Out = branch(32, a),
    Errors = [union_mismatch(#,[
        [not_integer(#,branch(32,a))],
        [union_mismatch(# / branch(1),[
            [not_integer(# / branch(1),a)],
            [invalid_compound(# / branch(1),a)]
        ])]
    ])].