PASSED: 
add     $1, $2, $3
addu    $1, $2, $3
sub     $1, $2, $3
subu    $1, $2, $3
slt     $1, $2, $3
sltu    $1, $2, $3
div     $1, $2
divu    $1, $2
mult    $1, $2
multu   $1, $2
addi    $1, $2, 100
addiu   $1, $2, 100

AND $15, $10, $11
ANDI $11, $10, 3
LUI $11,3
NOR $15, $10, $11
OR $15, $10, $11
ORI $11, $10, 3

XOR $15, $10, $11 
XORI $11, $10, 3 

SLL $15, $11, 3 
SLLV $15, $11, $10 
SRA $15, $11, 3 
SRAV $15, $11, $10 
SRL $15, $11, 3 
SRLV $15, $11, $10 

MFHI $15  
MFLO $15  
MTHI $10 
MTLO $10 

BREAK 
SYSCALL 

LB $11, 4($20) 
LBU $11, 4($20) 
LH $11, 4($20) 
LHU $11, 4($20) 
LW $11, 4($20) 
SB $11, 4($20) 
SH $11, 4($20) 
SW $11, 4($20) 

ERET 
MFC0 
MTC0 


NOT_TESTED:
BEQ $10, $11, NOT_TESTED 
BNE $10, $11, NOT_TESTED 
BGEZ $10, NOT_TESTED 
BGTZ $10, NOT_TESTED 
BLEZ $10, NOT_TESTED 
BLTZ $10, NOT_TESTED 
BLTZAL $10, NOT_TESTED
BGEZAL $10, NOT_TESTED
J NOT_TESTED 
JAL NOT_TESTED 
JR $10 
JALR $15, $10