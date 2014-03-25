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
            year: _{ type: integer, min: 1672 },
            make: _{ type: atom, min_length: 1 },
            model: _{ type: atom, min_length: 1 }
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
            year: _{ type: integer, min: 1672 },
            make: _{ type: atom, min_length: 1 },
            model: _{ type: atom, min_length: 1 }
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

## Available types

All types below assume that input is either a ground or a dict with ground values.
Exceptions are `any` and `var`. A dict with an unbound tag is allowed depending
on its type's `tag` attribute.

### string

String type has the following optional attributes:

 * min_length - specifies the minimum length of the string.
 * max_length - specifies the maximum length of the string.

Errors:

 * When the input value is an atom, it is converted into a string. All
   other input values other than strings will produce
   an error `not_string(Path, Value)`.
 * The `min_length` property is violated: `min_length(Path, Value, MinLength)`.
 * The `max_length` property is violated: `max_length(Path, Value, MaxLength)`.

### atom

Works similar to the `string` type. When the input is a string,
it is converted into an atom. Has same optional attributes.
When input is not a string or atom, an error
term `not_atom(Path, Value)` is produced.

### number

Number type has the following optional attributes:

 * min - specifies the minimum value of the number.
 * max - specifies the maximum value of the number.

Errors:

 * Value is not a number: `not_number(Path, Value)`.
 * The `min` property is violated: `min(Path, Value, Min)`.
 * The `max` property is violated: `max(Path, Value, Max)`.

### integer

Same as the type `number` but allows integers only.

### bool

The bool type only allows atoms `true` and `false`. Produces
error `not_bool(Path, Value)` when the input is not one of those.

### enum

The enum type has attribute `values` that contains a list of allowed values.
The list must contain atoms. If the checked value is not in the list
then an error is produced. If the input value is a string then it is converted
into an atom first. All other values produce an error `not_enum(Path, Value)`.

### dict

The dict type has the following attributes:

 * tag - specifies the tag of the dict. When the input has unbound
   tag it will be unified with the specified tag. If the tag attribute
   is missing then no tag checking is performed.
 * keys - specifies dict keys and schemas for values.
 * optional - list of keys that are optional.
 * additional - specifies whether extra keys are allowed or not. Default
   value is `false`.

Errors:

 * Value not a dict: `not_dict(Path, Value)`.
 * When the `additional` property is missing or its value is `false` and
   every key is not listed in `keys`: `additional_key(Path, Key)`.
 * When a key in the input is missing: `no_key(Path, Key)`.
 * When the `tag` property is specified and the input's tag does not
   match it: `invalid_tag(Path, Tag, RequiredTag)`.

When the `tag` property is specified and the input has no tag then input's tag is
unified with the `tag` property value.

### list

The list type has the following attributes:

 * items - specifies the type of the list items.
 * min_length - specifies the minimum number of items (optional).
 * max_length - specifies the maximum number of items (optional).

Errors:

 * When the input is not a list: `not_list(Path, Value)`.
 * When the `min_length` property is violated: `min_length(Path, Value, MinLength)`.
 * When the `max_length` property is violated: `max_length(Path, Value, MaxLength)`.

### compound

The compound type has the following attributes:

 * name - the compound name.
 * arguments - the compound arguments.

Errors:

 * When the input is not a compound: `invalid_compound(Path, In)`.
 * When number of arguments does not match: `compound_args_length(Path, ActualLen, RequiredLen)`.
 * When the name does not match: `compound_name(Path, ActualName, Name)`.

### unions

Union of types can be expressed with using a list. The first schema and
the conversion result that matches is used. When no schema matches then
an error `union_mismatch(Path, Reasons)` is produced.

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

### any

Type `any` marks the value non-checked and non-converted.

### var

Type `var` is for variables in the input. When the input is not
a variable then an error term `not_variable(Path, Value)` is produced.

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

## Metavalidation

The schema is validated on-the-fly during the validation of the input term.
It is checked for valid attributes. Schema errors are thrown as exceptions
and are not placed into the `Errors` output list.

## API documentation

Generated API documentation can be found from here:
<http://packs.rlaanemets.com/dict-schema/doc>.
