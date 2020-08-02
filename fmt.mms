% Program to format MMIXAL source files.
        LOC     Data_Segment
* Buffers supporting lines of length 127 (128 - null character)
        GREG    @
InBufL  IS      128
InBufP  GREG    @                       Pointer to InBuf
InBuf   BYTE    0
        LOC     InBuf+InBufL
InBufA  OCTA    InBuf,InBufL
OutBufL IS      128
OutBufP GREG    @                       Pointer to OutBuf
OutBuf  BYTE    0
        LOC     OutBuf+OutBufL

* Main routine
        LOC     #100
        GREG    @
t       IS      $2
Main    SET     t,0
1H      LDA     $255,InBufA             Get next line from StdIn
        TRAP    0,Fgets,StdIn
        CMP     t,$255,0                if end-of-file, end program
        BN      t,2F
        PUSHJ   $3,Print                else, print formatted line
        JMP     1B                      loop
2H      TRAP    0,Halt,0

* Print(), formats InBuf line if possible and prints to standard out.
        PREFIX  Print:
t       IS      $0
i       IS      $1                      Our place in InBuf
j       IS      $2                      Our place in OutBuf
c       IS      $3                      Current character of InBuf
prev    IS      $4                      Previous character
Fields  BYTE    0,8,16,40,80            Field positions
f       IS      $5                      Number of complete fields or index to F
fj      IS      $6                      Current F value
fjj     IS      $7                      Next F value
return  IS      $8                      Return address
result  IS      $10                     Result from a subroutine call
arg1    IS      $11                     First argument to subroutine call

:Print  GET     return,:rJ
        SET     c,'a'                   (Any non-space character)
        SET     i,0                     Initialization
        SET     j,0
        SET     f,0
        LDA     t,Fields
        LDBU    fj,t,0
        LDBU    fjj,t,1

1H      ADDU    prev,c,0                prev = c
        LDBU    c,:InBufP,i             c = InBuf[i++]
        INCL    i,1

        CMP     t,c,' '                 if anything < ' ' is newline, 0, etc.
        BN      t,8F                    go 8F

        CMP     t,f,3                   if f < 3 , go 2F
        PBN     t,2F                    else,
        STBU    c,:OutBufP,j            OutBuf[j++] = c
        INCL    j,1
        JMP     1B

        * Don't format line if it contains %, *, ;, ", or ' in first fields.
2H      CMP     t,c,'%'
        BZ      t,9F
        CMP     t,c,'*'
        BZ      t,9F
        CMP     t,c,';'
        BZ      t,9F
        CMP     t,c,'"'                 TODO: Handle quotes better
        BZ      t,9F
        CMP     t,c,'''
        BZ      t,9F

        CMP     t,prev,' '              if prev is space, go 3F
        PBZ     t,3F
        CMP     t,prev,#9               (tab = #9)
        PBZ     t,3F                    else,

        CMP     t,c,' '                 if c is space, go 1B
        BZ      t,1B
        CMP     t,c,#9
        BZ      t,1B                    else,

        STBU    c,:OutBufP,j            OutBuf[j++] = c, go 1B
        INCL    j,1
        JMP     1B

3H      CMP     t,c,' '                 if c is space, go 1B
        PBZ     t,1B
        CMP     t,c,#9
        PBZ     t,1B                    else,

        INCL    f,1
        LDA     t,Fields
        LDBU    fj,t,f
        LDBU    fjj,t,f+1

4H      CMP     t,j,fj                  if j < f, go 5F
        PBN     t,5F                    else,

        STBU    c,:OutBufP,j
        INCL    j,1
        JMP     1B

5H      SET     t,' '
        STBU    t,:OutBufP,j
        INCL    j,1
        JMP     4B

        * Ending
8H      LDA     t,Fields                Get offset of third field
        LDBU    t,t,2
        CMP     t,j,16                  if j < third field, nothing in it
        BNP     t,9F                    go 9F, else

        LDA     t,:OutBuf               Add #a,0 to end of OutBuf
        SET     c,#a
        STBU    c,t,j
        INCL    j,1
        SET     c,0
        STBU    c,t,j

        LDA     arg1,:OutBuf
        PUSHJ   result,:Trim            Trim OutBuf
        PUT     :rJ,return
        LDA     $255,:OutBuf            Print OutBuf
        TRAP    0,:Fputs,:StdOut
        POP     0,0

9H      LDA     arg1,:InBuf
        PUSHJ   result,:Trim            Trim InBuf
        PUT     :rJ,return
        LDA     $255,:InBuf             Print InBuf
        TRAP    0,:Fputs,:StdOut
        POP     0,0


* Trim trailing whitespace, not including newline.
        PREFIX  Trim:
str     IS      $0                      Address of string to be modified
i       IS      $1                      Index into str
c       IS      $2                      Current character str[i]
t       IS      $3                      Temp
:Trim   SET     i,0
        * Find the end of the string.
1H      LDBU    c,str,i                 c = str[i]
        INCL    i,1                     i++
        CMP     t,c,0                   if c != 0, loop
        PBNZ    t,1B                    else

        * If i <= 2, return without modification
        CMP     t,i,2                   if i <= 2, go 4F (end)
        BNP     t,4F

        * Then count back till we find first nonspace char (i >= 0)
2H      CMP     t,i,0                   if i is 0, go 3F
        BZ      t,3F                    else,

        SUB     i,i,1                   i-- (go back one character)
        LDBU    c,str,i                 c = str[i]
        CMP     t,c,' '                 if c <= ' ' (i.e., whitespace), loop
        PBNP    t,2B
        INCL    i,1                     i++, set to next whitespace

        * Then set #a,0
3H      SET     c,#a                    add newline
        STBU    c,str,i
        INCL    i,1
        SET     c,0                     add null terminator
        STBU    c,str,i

4H      POP     0,0
