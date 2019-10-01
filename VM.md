# The Koota Virtual Machine

The Koota virtual machine runs Koota bytecode. It has the concept of _memory_,
which is a randomly-accessible field of opcodes, and an _output_, which is
where the generation result is.

At all times, the virtual machine is at a memory address or _offset_, which is
an unsigned 16-bit number (aka C `unsigned short`). The offset points to a
memory location; therefore, the maximum amount of memory possible is 64 KiB
(65536 bytes), which should be enough for any reasonable pattern.

The virtual machine’s starting offset is always `0x0000`.

There is also the concept of a _call stack_. Offsets are stored in that stack
by `call` to be used when `ret` is executed.

## Bytecode

Koota bytecode has the following opcodes:

| Opcode | Mnemonic | Description                                                 |
| -----: | -------- | :---------------------------------------------------------- |
| `0x00` | `halt`   | Halts the machine, stopping word generation.                |
| `0x01` | `jump`   | Jumps to the given offset.                                  |
| `0x02` | `put`    | Puts the given character in the output.                     |
| `0x03` | `pick`   | Randomly picks an offset in the given list and jumps to it. |
| `0x04` | `call`   | Calls subroutine.                                           |
| `0x05` | `ret`    | Returns from subroutine.                                    |

With these few opcodes, any Koota pattern can be “bytecodified”. In the
following section, they will be explained in more detail.

### Opcode `0x00`: `halt`

- **Arguments**: _none_
- **Total length**: 1 byte

When this opcode is run, the machine halts, with the generated word in the
output.

### Opcode `0x01`: `jump`

- **Arguments**: an _offset_ (2 bytes)
- **Total length**: 3 bytes

When this opcode is run, the virtual machine’s offset becomes the _offset_ argument,
and execution continues from there.

### Opcode `0x02`: `put`

- **Arguments**: an UTF-8 _character_ (1 to 4 bytes)
- **Total length**: 2 to 5 bytes

When this opcode is run, the virtual machine places the given _character_ at the end
of its output.

### Opcode `0x03`: `pick`

- **Arguments**: an _offset_ (2 bytes)
- **Total length**: 3 bytes

When this opcode is run, the given _offset_ is taken as the start pointer of a
list of offsets ending in two `0x00` bytes. Then, an offset in that list is
randomly picked, and that offset is `jump`ed to.

### Opcode `0x04`: `call`

- **Arguments**: an _offset_ (2 bytes)
- **Total length**: 3 bytes

When this opcode is run, the current offset plus one (i.e. the offset that would
be ran if the `call` wasn’t there) is pushed to the _call stack_, and the given
offset is `jump`ed to.

### Opcode `0x05`: `ret`

- **Arguments**: _none_
- **Total length**: 1 byte

When this opcode is run, the topmost offset in the _call stack_ is `jump`ed to
and the call stack is popped. This effectively returns to the next opcode after
the last `call`, completing the subroutine.

If the call stack is empty, the virtual machine should put the string
`<ret with empty stack>` in the output then immediately `halt`.

### Unrecognised opcodes

If the virtual machine finds an unrecognised opcode, it must `halt`.

### Out of bounds

If the virtual machine tries to access an offset out of bounds of its memory,
it must `halt`.
