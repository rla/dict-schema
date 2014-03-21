# dict-schema

Dict validation/conversion for Swi-Prolog.

## Primitive values

### string

String type has the following attributes:

 * min_length - specifies the minimum length of the string.
 * max_length - specifies the maximum length of the string.

When the input value is an atom, it is converted into a string. All
other input values other than strings will produce an error.

### atom

Atom type has the following attributes:

 * min_length - specifies the minimum length of the atom.
 * max_length - specifies the maximum length of the atom.

When the input value is a string, it is converted into an atom. All
other input values other than atoms will produce an error.

### number

Number type has the following attributes:

 * min - specifies the minimum value of the number.
 * max - specifies the maximum value of the number.

All other values than numbers will produce an error.

### integer

Same as the type `number` but allows integers only.

### enum

The enum type has attribute `values` that contains a list of allowed values.
The list must contain atoms. If the checked value is not in the list,
an error is produced. If the input value is a string, it is converted
into an atom first. All other values produce an error.

## Composite values

### dict

The dict type has the following attributes:

 * tag - specifies the tag of the dict. When the input has unbound
   tag, it will be unified with the specified tag. The tag attribute
   might be missing, then no checking is performed.
 * keys - specifies dict keys and schemas for values.
 * optional - list of keys that are optional.

### list

The list type has the following attributes:

 * items - specifies the type of the list items.
 * min_length - specifies the minimum number of items.
 * max_length - specifies the maximum number of items.

### compound term

## Wildcards

### any

Type `any` marks the value non-checked and non-converted.

### ignore

Type `ignore` marks the value as non-checked. The value will
not appear in the output.

## Type references

Type `ref(Name)` references a named schema. This makes it possible
to implement recursive schemas to check/converts trees.
