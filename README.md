# MMIX Assembly Language Auto-Formatting Tool

This tool handles basic automatic formatting of MMIXAL files (.mms), including:

- Aligning label, opcode, operand, and remark fields.
- Converting opcodes to uppercase.
- Removing trailing whitespace.

The idea is to turn a lazily written code like

```asm
 loc #100
1H SET $1,0 Set the counter to 0.
 addu x,x,$1
```

into

```asm
            LOC     #100
1H          SET     $1,0                Set the counter to 0.
            ADDU    x,x,$1
```

The instruction's fields are as follows:

```asm
% Label     Opcode  Operands            Remark
1H          SET     $1,0                Set the counter to 0.
```

The number of columns preceding the label, opcode, operands, and remark fields are, respectively: 0,12,20,40. This gives an appearance similar to most example code in "The Art of Computer Programming," but fields are aligned to multiples of four to make life easier for folks who use four space tab indents. This can of course be adjusted by changing the `Fields` in "fmt.mms" and reassembling the program. (Note: having a field width of 12 for the first field allows for longer, less restrictive label names, such as `:StackRoom`.)

Trailing whitespace is removed from all lines, even when the program gives up trying to format a line (as in the case of string literals in the operand field).

## Building and running

The MMIX compiler and simulator--"mmixal" and "mmix", respectively--can be found on the [MMIX website](http://mmix.cs.hm.edu/).

The program can be run through the assembler with the command `mmixal fmt.mms`, which generates the "fmt.mmo" object file. This in turn can be run by the simulator with the command `mmix fmt.mmo`, which formats each line of standard input.

A file can be routed standard input with the MMIX simulator by using the `-f<filename>` flag. For example, echo the *formatted* result of some "myfile.mms", we could invoke `mmix -fmyfile.mms fmt.mmo`. (The resulting text would be printed to standard output.)

Unfortunately, we can't directly use that output to replace the input file (e.g., "myfile.mms"). We can, however, use a temporary file, along with some common existing command line utilities. Thus, if we want to shore up the formatting on "myfile.mms", we could run the following chain of commands:

`mmix -fmyfile.mms fmt.mmo > temp.mms && cat temp.mms > myfile.mms`

> Note: I have elected not to include the assembler and simulator programs in the repo. It's simple enough to download these programs directly from the MMIX site.

## What is MMIX and MMIXAL?

The MMIX is a hypothetical machine designed by Donald Knuth for his book series, "The Art of Computer Programming," published by Addison-Wesley. It is an idealized RISC-based architecture meant to be fun to work with while demonstrating how algorithms (the subject of the book series) work at the machine level. MMIXAL is the assembly language for the MMIX machine.

An assembly file (.mms) gets converted into an object file (.mmo) by the assembler (the "mmixal" program). The resulting object file can be run on the simulator (the "mmix" program), which gets wired up to standard input and output.

More information on MMIX can be found on the [MMIX website](http://mmix.cs.hm.edu/).

## Known Issues and Future Work

### Literal space character

Unfortunately, using a single-quoted literal space character in the operand field aligns the trailing single quote to the remark field, as follows:

```asm
*           CMP     t,c,' '             Whoops! This results in:
            CMP     t,c,'               '
* Instead, we want to do the following:
            CMP     t,c,#20             #20 == ' '.
```

This has to do with a simplification in how the formatter distinguishes fields (i.e., by *any* whitespace). Thus, it is advisable to use a `#20` in place of the literal space character.

It is, however, permissible to use a `' '` space literal (with the single quotes) in the remarks field, as no further field alignment occurs after the remark field.

### String literals

Similar to the space literal `' '`, string literals can cause issues in the operand field if they contain spaces. There are other cases where long string literals can cause issues, though further testing is needed to identify the particular cause. Therefore, a line with a string literal in the first three fields is just printed without any attempt at formatting (except removing trailing whitespace).
