;========1=========2=========3=========4=========5=========6=========7=========8=========9=========0=========1=========2=========3=========4=========5=========6=========7**
;Author information
;  Author name: Sina Amini	
;  Author email: sinamindev@gmail.com
;Project information
;  Project title: Amortization Schedule
;  Purpose: To experience vector processing, input data, linking 3 objects, and formatting output data
;  Status: No known errors
;  Project files: amortization-schedule-driver.cpp, amortization-schedule.asm, payment_calculator.cpp
;Module information
;  This module's call name: amortization_schedule
;  Language: X86-64
;  Syntax: Intel
;  Date last modified: 2014-Sep-27
;  Purpose: This module will read an interest rate, 4 loan amounts, and the duration of the loan in months. Then analyze monthly payments and interest due.
;  File name: amortization-schedule.asm
;  Status: This module functions as expected.
;  Future enhancements: None planned
;Translator information
;  Linux: nasm -f elf64 -l amortization-schedule.lis -o amortization-schedule.o amortization-schedule.asm 
;References and credits
;  Seyfarth
;  Professor Holliday public domain programs
;Format information
;  Page width: 172 columns
;  Begin comments: 61
;  Optimal print specification: Landscape, 7 points or smaller, monospace, 8½x11 paper
;
;===== Begin code area ====================================================================================================================================================
extern printf                                               ;External C++ function for writing to standard output device

extern scanf                                                ;External C++ function for reading from the standard input device

extern payment_calc				            				;External C++ function for computing the monthly payments

global amortization_schedule                                ;This makes amortization_schedule callable by functions outside of this file.

segment .data                                               ;Place initialized data here

;===== Declare some messages ==============================================================================================================================================

initialmessage 		db "Welcome to the Bank of Binary ", 10
	       			db "Sina Amini, Chief Loan Officer ", 10,0

promptmessage0 		db "Please enter the current interest rate as a float number: ", 0

promptmessage1 		db "Enter the amounts of four loans: ", 0

promptmessage2 		db "Enter the time of the loans as a whole number of months: ", 0

promptsuccess 		db "Condensed amortization schedules for the four possible loans are as follows ", 10, 10, 0

outputloan 			db "Loan amounts:             %8.2lf %8.2lf %8.2lf %8.2lf",10, 0

outputmonthly 		db "Monthly payment amount:   %8.2lf %8.2lf %8.2lf %8.2lf", 10, 0

outputinterestdue 	db "Interest due by months: %ld %8.2lf %8.2lf %8.2lf %8.2lf ", 10, 0

outputtotalinterest db "Total interest:            %8.2lf %8.2lf %8.2lf %8.2lf", 10, 10, 0

goodbye 			db "Thank you for you inquiry at our bank", 10
        			db "This program will now return the toal interest of the last loan to the driver. ", 10, 10, 0

xsavenotsupported.notsupportedmessage db "The xsave instruction and the xrstor instruction are not supported in this microprocessor.", 10
                                      db "However, processing will continue without backing up state component data", 10, 0

stringformat 		db "%s", 0                          ;general string format

xsavenotsupported.stringformat db "%s", 0

eight_byte_format 	db "%lf", 0                         ;general 8-byte float format

integer_format 		db "%ld",0		            		;general integer format

fourfloatformat     db "%lf %lf %lf %lf", 0	            ;general four float format

monthlyformat		db "                        %ld %8.2lf %8.2lf %8.2lf %8.2lf",10, 0

segment .bss                                                ;Place un-initialized data here.

align 64                                                    ;Insure that the inext data declaration starts on a 64-byte boundar.
backuparea resb 832                                         ;Create an array for backup storage having 832 bytes.

;===== Begin executable instructions here =================================================================================================================================

segment .text                                               ;Place executable instructions in this segment.

amortization_schedule:                                      ;Entry point.  Execution begins here.

;=========== Back up all the GPRs whether used in this program or not =====================================================================================================

push       rbp                                              ;Save a copy of the stack base pointer
mov        rbp, rsp                                         ;We do this in order to be 100% compatible with C and C++.
push       rbx                                              ;Back up rbx
push       rcx                                              ;Back up rcx
push       rdx                                              ;Back up rdx
push       rsi                                              ;Back up rsi
push       rdi                                              ;Back up rdi
push       r8                                               ;Back up r8
push       r9                                               ;Back up r9
push       r10                                              ;Back up r10
push       r11                                              ;Back up r11
push       r12                                              ;Back up r12
push       r13                                              ;Back up r13
push       r14                                              ;Back up r14
push       r15                                              ;Back up r15
pushf                                                       ;Back up rflags

;==========================================================================================================================================================================
;===== Begin State Component Backup =======================================================================================================================================
;==========================================================================================================================================================================

;=========== Before proceeding verify that this computer supports xsave and xrstor ========================================================================================
;Bit #26 of rcx, written rcx[26], must be 1; otherwise xsave and xrstor are not supported by this computer.
;Preconditions: rax holds 1.
mov        rax, 1

;Execute the cpuid instruction
cpuid

;Postconditions: If rcx[26]==1 then xsave is supported.  If rcx[26]==0 then xsave is not supported.

;=========== Extract bit #26 and test it ==================================================================================================================================

and        rcx, 0x0000000004000000                          ;The mask 0x0000000004000000 has a 1 in position #26.  Now rcx is either all zeros or
                                                            ;has a single 1 in position #26 and zeros everywhere else.
cmp        rcx, 0                                           ;Is (rcx == 0)?
je         xsavenotsupported                                ;Skip the section that backs up state component data.

;========== Call the function to obtain the bitmap of state components ====================================================================================================

;Preconditions
mov        rax, 0x000000000000000d                          ;Place 13 in rax.  This number is provided in the Intel manual
mov        rcx, 0                                           ;0 is parameter for subfunction 0

;Call the function
cpuid                                                       ;cpuid is an essential function that returns information about the cpu

;Postconditions (There are 2 of these):

;1.  edx:eax is a bit map of state components managed by xsave.  At the time this program was written (2014 June) there were exactly 3 state components.  Therefore, bits
;    numbered 2, 1, and 0 are important for current cpu technology.
;2.  ecx holds the number of bytes required to store all the data of enabled state components. [Post condition 2 is not used in this program.]
;This program assumes that under current technology (year 2014) there are at most three state components having a maximum combined data storage requirement of 832 bytes.
;Therefore, the value in ecx will be less than or equal to 832.

;Precaution: As an insurance against a future time when there will be more than 3 state components in a processor of the X86 family the state component bitmap is masked to
;allow only 3 state components maximum.

mov        r15, 7                                           ;7 equals three 1 bits.
and        rax, r15                                         ;Bits 63-3 become zeros.
mov        r15, 0                                           ;0 equals 64 binary zeros.
and        rdx, r15                                         ;Zero out rdx.

;========== Save all the data of all three components except GPRs =========================================================================================================

;The instruction xsave will save those state components with on bits in the bitmap.  At this point edx:eax continues to hold the state component bitmap.

;Precondition: edx:eax holds the state component bit map.  This condition has been met by the two pops preceding this statement.
xsave      [backuparea]                                     ;All the data of state components managed by xsave have been written to backuparea.

jmp        startapplication

;========== Show message xsave is not supported on this platform ==========================================================================================================
xsavenotsupported:

mov        rax, 0
mov        rdi, .stringformat
mov        rsi, .notsupportedmessage                        ;"The xsave instruction is not suported in this microprocessor.
call       printf

;==========================================================================================================================================================================
;===== End of State Component Backup ======================================================================================================================================
;==========================================================================================================================================================================


;==========================================================================================================================================================================
startapplication: ;===== Begin the application here: Amortization Schedule ================================================================================================
;==========================================================================================================================================================================

vzeroall						    ;place binary zeros in all components of all vector register in SSE

;==== Show the initial message ============================================================================================================================================

mov qword  rax, 0                                           ;No data from SSE will be printed
mov        rdi, stringformat                                ;"%s"
mov        rsi, initialmessage                              ;"Welcome to the Bank of Binary" "Sina Amini, Chief Loan Officer"
call       printf                                           ;Call a library function to make the output

;==== Prompt for floating point number ====================================================================================================================================

mov qword  rax, 0                                           ;No data from SSE will be printed
mov        rdi, stringformat                                ;"%s"
mov        rsi, promptmessage0                              ;"Please enter the current interest rate as a float number: "
call       printf                                           ;Call a library function to make the output

;==== Obtain a floating point number from the standard input device and store a copy in xmm10 =============================================================================

push qword 0                                                ;Reserve 8 bytes of storage for the incoming number
mov qword  rax, 0                                           ;SSE is not involved in this scanf operation
mov        rdi, eight_byte_format                           ;"%lf"
mov        rsi, rsp                                         ;Give scanf a point to the reserved storage
call       scanf                                            ;Call a library function to do the input work
vbroadcastsd ymm14, [rsp]				    ;move amount annual interest rate from stack into ymm14
pop rax							    ;Make free the storage that was used by scanf

;==== Prompt for 4 floating point numbers =================================================================================================================================

mov   rax, 0                                                ;No data from SSE will be printed
mov        rdi, stringformat                                ;"%s"
mov        rsi, promptmessage1                              ;"Enter the amounts of four loans: "
call       printf                                           ;Call a library function to make the output

;==== Scan 4 floating point numbers========================================================================================================================================

push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number

mov qword   rax, rsp					    ;move to the top of the stack
mov	    rdi, fourfloatformat			    ;point to floating-point numer format: '%lf %lf %lf %lf'
mov         rsi, rax					    ;point to top space on stack so the 1st value can be put here by scanf()
add         rax, 8					    ;add one 8-byte 'chunk' to move 'down' lower in stack 
mov         rdx, rax					    ;point to second space on stack so the 2nd value can be put here by scanf()
add         rax, 8					    ;add one 8-byte 'chunk' to move 'down' lower in stack 
mov         rcx, rax					    ;point to third space on stack so the 3rd value can be put here by scanf()
add         rax, 8					    ;add one 8-byte 'chunk' to move 'down' lower in stack 
mov         r8, rax				            ;point to fourth space on stack so the 4th value can be put here by scanf()
mov qword   rax, 0				            ;no floating-point values output from ymm registers
call        scanf					    ;call scanf function
 
vmovupd     ymm15, [rsp]			            ;move amount of 4 loans from stack into ymm15 register
vmovupd     ymm10, [rsp]

pop rax							    ;Make free the storage that was used by scanf
pop rax							    ;Make free the storage that was used by scanf
pop rax							    ;Make free the storage that was used by scanf
pop rax							    ;Make free the storage that was used by scanf

;==== Prompt for integer number ===========================================================================================================================================

mov qword  rax, 0                                           ;No data from SSE will be printed
mov        rdi, stringformat                                ;"%s"
mov        rsi, promptmessage2                              ;"Enter the time of the loans as a whole number of months: "
call       printf                                           ;Call a library function to make the output

;==== Obtain an integer number from the standard input device and store a copy in r15 =====================================================================================

push dword 0						    ;Reserve 4 bytes of storage for the incoming integer
mov qword  rax, 0                                           ;SSE is not involved in this scanf operation                                          
mov        rdi, integer_format                              ;"%d"
mov        rsi,rsp                                          ;Give scanf a point to the reserved storage
call       scanf                                            ;Call a library function to do the input work

mov        r15, [rsp]			                    ;move the time of loans as an integer into the gpr r15
pop rax							    ;Make free the storage that was used by scanf

;==== Show success message ================================================================================================================================================

mov qword  rax, 0                                           ;0 floating point numbers will be outputted
mov        rdi, stringformat                                ;Prepare printf for string output
mov        rsi, promptsuccess                               ;"Condensed amortization schedules for the four possible loans are as follows." 
call       printf                                           ;Call a library function to do the hard work

;======== Output Loan amounts =============================================================================================================================================
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number

vmovupd [rsp], ymm15					    ;copy values from ymm15 onto stack

movsd      xmm0, [rsp]		                            ;move first value from stack into xmm0
pop rax							    ;Make free the storage that was used by scanf
movsd      xmm1, [rsp]		                            ;move first value from stack into xmm1
pop rax							    ;Make free the storage that was used by scanf
movsd      xmm2, [rsp]		                            ;move first value from stack into xmm2
pop rax							    ;Make free the storage that was used by scanf
movsd      xmm3, [rsp]		                            ;move first value from stack into xmm3
pop rax							    ;Make free the storage that was used by scanf

mov        rax, 4                                           ;4 floating point numbers will be outputted
mov        rdi, outputloan                                  ;"Loan amounts: %1.18lf %1.18lf %1.18lf %1.18lf"
call       printf                                           ;Call a library function to do the hard work

;==== Push stack to prepare for function call =============================================================================================================================

mov  rdi, r15    					    ;copy integer value from r15 into rdi

push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number

;========== Move all the data to SSE ======================================================================================================================================

vmovupd    [rsp], ymm15					    ;move ymm15 onto stack
movsd      xmm0, [rsp]                                      ;Copy 8-byte float number to register xmm0                                  
movupd     xmm1, xmm14                                      ;Copy 8-byte float number to register xmm1

;=========== Call the external C++ function 1st time ======================================================================================================================
;Preconditions for payment_calculator:			    ;Declare preconditions
;    The first parameter is in xmm0
;    The second parameter is in xmm1
;    The third parameter is in xmm2
call       payment_calc                                     ;Control is passed to payment_calc

;    Postconditions for payment_calculator:	            ;Declare postconditions
;    The returned value is in xmm0

movsd      [rsp+32], xmm0				    ;move xmm0 into stack at postion 32
movsd      [rsp], xmm0				            ;move xmm0 into stack at the first position

;========== Move all the data to SSE ======================================================================================================================================

movupd      xmm1, xmm14                                     ;Copy 8-byte float number to register xmm1
movsd       xmm0, [rsp+8]				    ;Copy 8-byte float number to register xmm0 

;=========== Call the external C++ function 2nd time ======================================================================================================================
;Preconditions for payment_calculator:			    ;Declare preconditions
;    The first parameter is in xmm0
;    The second parameter is in xmm1
;    The third parameter is in xmm2
call       payment_calc                                     ;Control is passed to payment_calc

;    Postconditions for payment_calculator:	            ;Declare postconditions
;    The returned value is in xmm0

movsd      [rsp+40], xmm0				    ;move xmm0 into stack at postion 40
movsd      [rsp+8], xmm0				    ;move xmm0 into stack at postion 8

;========== Move all the data to SSE ======================================================================================================================================

movupd      xmm1, xmm14                                     ;Copy 8-byte float number to register xmm1              
movsd       xmm0, [rsp+16]				    ;Copy 8-byte float number to register xmm0 

;=========== Call the external C++ function 3rd time ======================================================================================================================
;Preconditions for payment_calculator:			    ;Declare preconditions
;    The first parameter is in xmm0
;    The second parameter is in xmm1
;    The third parameter is in xmm2
call       payment_calc                                     ;Control is passed to payment_calc

;    Postconditions for payment_calculator:	            ;Declare postconditions
;    The returned value is in xmm0

movsd      [rsp+48], xmm0				    ;move xmm0 into stack at postion 48
movsd      [rsp+16], xmm0				    ;move xmm0 into stack at postion 16

;========== Move all the data to SSE ======================================================================================================================================
       
movupd      xmm1, xmm14                                     ;Copy 8-byte float number to register xmm1           
movsd       xmm0, [rsp+24]                                  ;Copy 8-byte float number to register xmm0 
          
;=========== Call the external C++ function 4th time ======================================================================================================================
;Preconditions for payment_calculator:			    ;Declare preconditions
;    The first parameter is in xmm0
;    The second parameter is in xmm1
;    The third parameter is in xmm2
call       payment_calc                                     ;Control is passed to payment_calc

;    Postconditions for payment_calculator:	            ;Declare postconditions
;    The returned value is in xmm0

movsd      [rsp+56], xmm0				    ;move xmm0 into stack at postion 56
movsd      [rsp+24], xmm0				    ;move xmm0 into stack at postion 24

;===== Save monthly payments to ymm13 =====================================================================================================================================

vmovupd    ymm13, [rsp]					    ;move monthly payments from the stack into ymm13
pop rax							    ;Make free the storage that was used by scanf
pop rax							    ;Make free the storage that was used by scanf
pop rax							    ;Make free the storage that was used by scanf
pop rax							    ;Make free the storage that was used by scanf

;==== Move stack into xmm registers to output monthly payments=============================================================================================================

movsd 	    xmm0, [rsp]					    ;move first value from stack into xmm0
pop rax							    ;Make free the storage that was used by scanf
movsd       xmm1, [rsp]					    ;move first value from stack into xmm1
pop rax							    ;Make free the storage that was used by scanf
movsd       xmm2, [rsp]					    ;move first value from stack into xmm2
pop rax							    ;Make free the storage that was used by scanf
movsd       xmm3, [rsp]					    ;move first value from stack into xmm3
pop rax							    ;Make free the storage that was used by scanf

;======= Output Monthly payment amounts ===================================================================================================================================

mov        rax, 4                                           ;4 floating point numbers will be outputted
mov        rdi, outputmonthly                               ;"Monthly payment amount: %8.2lf %8.2lf %8.2lf %8.2lf"
call       printf                                           ;Call a library function to do the hard work

;======= For-loop to compute monthly payments =============================================================================================================================
mov rbx, 0						    ;rbx holds zero

;precondition						    ;declare preconditions
;r15 holds # of months
;rbx holds 0
;ymm13 holds monthly payments

topofloop:						    ;location of top of loop

vmulpd      ymm12, ymm15, ymm14 		            ;multiply ymm15 and ymm14 to find monthly amount of interest and save into ymm12

vaddpd      ymm11, ymm11, ymm12			            ;add ymm12 and ymm11 for accumulation and save into ymm11 

inc rbx							    ;incrament rbx by one
cmp rbx, 2						    ;compares rbx with the value 2
jge print2					            ;jumps to print2 if rbx is greater than or equal to 2

;==== Prints first line of interest due by months =========================================================================================================================

mov rdx, 0						    ;move 0 into rdx
mov rax, 7						    ;move 7 into rax
xsave [backuparea]					    ;save to the back up area

push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number

vmovupd [rsp], ymm12					    ;copy accumlated interest values from ymm12 to the stack

movsd      xmm0, [rsp]		                            ;move first value from stack into xmm0
pop rax							    ;Make free the storage that was used by scanf
movsd      xmm1, [rsp]		                            ;move first value from stack into xmm1
pop rax							    ;Make free the storage that was used by scanf
movsd      xmm2, [rsp]		                            ;move first value from stack into xmm2
pop rax							    ;Make free the storage that was used by scanf
movsd      xmm3, [rsp]		                            ;move first value from stack into xmm3
pop rax							    ;Make free the storage that was used by scanf

mov   qword rax, 4                                          ;4 data from SSE will be printed
mov         rdi, outputinterestdue                          ;"Interest due by months: %d %8.2lf %8.2lf %8.2lf %8.2lf "
mov   qword rsi, rbx					    ;data in rbx will be printed
call        printf                                          ;Call a library function to do the hard work

mov rdx, 0						    ;move 0 into rdx
mov rax, 7						    ;move 7 into rax
xrstor [backuparea]					    ;restore the back up area

jmp end2						    ;jump to the end2 position

;==== Prints rest of lines for interest due by months ===================================================================================================================== 
print2:							    ;jumps here if rax is greater than or equal to 2

mov rdx, 0						    ;move 0 into rdx
mov rax, 7						    ;move 7 into rax
xsave [backuparea]					    ;save to the back up area
			
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number

vmovupd [rsp], ymm12					    ;copy accumlated interest values from ymm12 to the stack

movsd      xmm0, [rsp]		                            ;move first value from stack into xmm0
pop rax							    ;Make free the storage that was used by scanf
movsd      xmm1, [rsp]		                            ;move first value from stack into xmm1
pop rax							    ;Make free the storage that was used by scanf
movsd      xmm2, [rsp]		                            ;move first value from stack into xmm2
pop rax							    ;Make free the storage that was used by scanf
movsd      xmm3, [rsp]		                            ;move first value from stack into xmm3
pop rax							    ;Make free the storage that was used by scanf

mov   qword rax, 4                                          ;4 data from SSE will be printed
mov         rdi, monthlyformat                              ;"%d %8.2lf %8.2lf %8.2lf %8.2lf "
mov   qword rsi, rbx					    ;data in rbx will be printed
call        printf  				            ;Call a library function to do the hard work

mov rdx, 0						    ;move 0 into rdx
mov rax, 7						    ;move 7 into rax
xrstor [backuparea]					    ;restore the back up area
end2:							    ;location of end2

vaddpd ymm15, ymm15, ymm12			    	    ;add ymm13 to ymm15 and store in ymm15 

vsubpd ymm15, ymm15, ymm13 		            	    ;subtract ymm15 by ymm13 and store in ymm15 

cmp  rbx, r15 						    ;cmp = compares 2 integers
jge outofloop						    ;jge = jumps   /is it true rbx >= r15 /Jump if Greater or Equal

jmp topofloop						    ;jumps to top of loop
outofloop:						    ;exits the loop

;postcondition						    ;declare postconditions
;rbx has the same value as r15
;ymm11 holds the total interest value

;==== Move stack into xmm registers to output total interest===============================================================================================================

push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0						    ;Reserve 8 bytes of storage for the incoming number
push qword 0		                                    ;Reserve 8 bytes of storage for the incoming number
 
vmovupd [rsp], ymm11					    ;copy accumlated interest values from ymm11 to the stack

movsd 	    xmm0, [rsp]					    ;move first value from stack into xmm0
pop rax							    ;Make free the storage that was used by scanf
movsd       xmm1, [rsp]					    ;move first value from stack into xmm1
pop rax							    ;Make free the storage that was used by scanf
movsd       xmm2, [rsp]					    ;move first value from stack into xmm2
pop rax							    ;Make free the storage that was used by scanf
movsd       xmm3, [rsp]					    ;move first value from stack into xmm3
pop rax							    ;Make free the storage that was used by scanf

;===== Save a copy of the last interest value before calling printf =======================================================================================================

movsd      [rsp], xmm3                                      ;Place a backup copy of the quotient in the reserved storage

;===== Output total interest ==============================================================================================================================================

mov        rax, 4                                           ;4 floating point numbers will be outputted
mov        rdi, outputtotalinterest                         ;"Total interest: %8.2lf %8.2lf %8.2lf %8.2lf"
call       printf                                           ;Call a library function to do the hard work
					 
;===== Conclusion message =================================================================================================================================================
 
mov qword  rax, 0                                           ;No data from SSE will be printed
mov        rdi, stringformat                                ;"%s"
mov        rsi, goodbye                                     ;"Thank you for you inquiry at our bank." 
							    ;"This program will now return the toal interest of the last loan to the driver. "
call       printf                                           ;Call a llibrary function to do the hard work.

;===== Retrieve a copy of the quotient that was backed up earlier =========================================================================================================

pop        r14                                              ;A copy of the last interest value  within r14 (temporary storage)

;Now the stack is in the same state as when the application area was entered.  It is safe to leave this application area.

;==========================================================================================================================================================================
;===== Begin State Component Restore ======================================================================================================================================
;==========================================================================================================================================================================

;===== Check the flag to determine if state components were really backed up ==============================================================================================

pop        rbx                                              ;Obtain a copy of the flag that indicates state component backup or not.
cmp        rbx, 0                                           ;If there was no backup of state components then jump past the restore section.
je         setreturnvalue                                   ;Go to set up the return value.

;Continue with restoration of state components;

;Precondition: edx:eax must hold the state component bitmap.  Therefore, go get a new copy of that bitmap.

;Preconditions for obtaining the bitmap from the cpuid instruction
mov        rax, 0x000000000000000d                          ;Place 13 in rax.  This number is provided in the Intel manual
mov        rcx, 0                                           ;0 is parameter for subfunction 0

;Call the function
cpuid                                                       ;cpuid is an essential function that returns information about the cpu

;Postcondition: The bitmap in now in edx:eax

;Future insurance: Make sure the bitmap is limited to a maximum of 3 state components.
mov        r15, 7
and        rax, r15
mov        r15, 0
and        rdx, r15

xrstor     [backuparea]

;==========================================================================================================================================================================
;===== End State Component Restore ========================================================================================================================================
;==========================================================================================================================================================================


setreturnvalue: ;=========== Set the value to be returned to the caller ===================================================================================================

push       r14                                              ;r15 continues to hold the first computed floating point value.
movsd      xmm0, [rsp]                                      ;That first computed floating point value is copied to xmm0[63-0]
pop        r14                                              ;Reverse the push of two lines earlier.

;=========== Restore GPR values and return to the caller ==================================================================================================================

popf                                                        ;Restore rflags
pop        r15                                              ;Restore r15
pop        r14                                              ;Restore r14
pop        r13                                              ;Restore r13
pop        r12                                              ;Restore r12
pop        r11                                              ;Restore r11
pop        r10                                              ;Restore r10
pop        r9                                               ;Restore r9
pop        r8                                               ;Restore r8
pop        rdi                                              ;Restore rdi
pop        rsi                                              ;Restore rsi
pop        rdx                                              ;Restore rdx
pop        rcx                                              ;Restore rcx
pop        rbx                                              ;Restore rbx
pop        rbp                                              ;Restore rbp

ret                                                         ;No parameter with this instruction.  This instruction will pop 8 bytes from
                                                            ;the integer stack, and jump to the address found on the stack.
;========== End of program amortization-schedule.asm =======================================================================================================================
;========1=========2=========3=========4=========5=========6=========7=========8=========9=========0=========1=========2=========3=========4=========5=========6=========7**