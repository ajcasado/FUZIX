        .module crt0

	;
	;	High space - read only 
	;

        .area _CODE
	.area _CODE2
	;
	;	Try and keep code in the top 32K
	;


	;
	;	Our common lives low
	;
	.area _CODE3
        .area _VIDEO		; must end below 0x4000
		.area _FONT
		.area _INITIALIZED
        .area _HOME
	.area _CONST

	;
	;	Beyond this point we just zero.
	;

        .area _DATA
        .area _BSEG
        .area _BSS
        .area _HEAP
        .area _GSINIT
        .area _GSFINAL
	
	;
	;	Finally the buffers so they can expand
	;
	.area _BUFFERS
	; Somewhere to throw it out of the way
        .area _INITIALIZER

        .area _DISCARD


		.ds 24


        .area _COMMONMEM

		

        ; imported symbols
        .globl _fuzix_main
        .globl init_early
        .globl init_hardware
	.globl l__BUFFERS
	.globl s__BUFFERS
	.globl l__COMMONMEM
	.globl s__COMMONMEM
	.globl l__DATA
	.globl s__DATA
	.globl l__DISCARD
	.globl s__DISCARD
	.globl l__FONT
	.globl s__FONT
        .globl kstack_top

        .globl unix_syscall_entry
        .globl nmi_handler
        .globl interrupt_handler

	.include "kernel.def"
	.include "../../cpu-z80/kernel-z80.def"

	;
        ; startup code
	;
	; We loaded the rest of the kernel from disk and jumped here
	;

        .area _CODE

	.globl _start



_start:


	di

	;clear loader traces
	ld hl, #0xFC00
	ld de, #0xFC01
	ld bc, #0x3FF
	ld (hl), #0
	ldir

	ld sp, #kstack_top
	;
	; move the common memory where it belongs    
	ld hl, #s__DATA
	ld de, #s__COMMONMEM
	ld bc, #l__COMMONMEM
	ldir


	; then the discard (backwards as will overlap)
	ld de, #s__DISCARD
	ld bc, #l__DISCARD-1
	ex de,hl
	add hl,bc
	ex de,hl
	add hl,bc
	lddr
	ldd
	
	; then zero the data area
	ld hl, #s__DATA
	ld de, #s__DATA + 1
	ld bc, #l__DATA - 1
	ld (hl), #0
	ldir
	; and buffers
	ld hl, #s__BUFFERS
	ld de, #s__BUFFERS + 1
	ld bc, #l__BUFFERS - 1
	ld (hl), #0
	ldir

	;call copyfont
	
        ; Configure memory map
        call init_early

        ; Hardware setup
        call init_hardware

        ; Call the C main routine
        call _fuzix_main
    
        ; main shouldn't return, but if it does...
        di
stop:   halt
        jr stop

	.area _BUFFERS
;
; Buffers (we use asm to set this up as we need them in a special segment
; so we can recover the discard memory into the buffer pool
;

	.globl _bufpool
	.area _BUFFERS

_bufpool:
	.ds BUFSIZE * NBUFS

