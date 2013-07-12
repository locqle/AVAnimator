// This file implements the following C functions for the ARM platform.
// Both ARM6 and ARM7 devices are supported by this implementation.
//
// maxvid_decode_c4_sample16()
// maxvid_decode_c4_sample32()

// This ARM asm file will generate an error with clang 4 (xcode 4.5 and newer) because
// the integrated assembler does not accept AT&T syntax. This .s target will need to
// have the "-no-integrated-as" command line option passed via
// "Target" -> "Build Phases" -> "maxvid_decode_arm.s"

#if defined(__arm__)
# define COMPILE_ARM 1
# if defined(__thumb__)
#  define COMPILE_ARM_THUMB_ASM 1
# else
#  define COMPILE_ARM_ASM 1
# endif
#endif

// Xcode 4.2 supports clang only, but the ARM asm integration depends on specifics
// of register allocation and as a result only works when compiled with gcc.

#if defined(__clang__)
#  define COMPILE_CLANG 1
#endif // defined(__clang__)

// For CLANG build on ARM, skip this entire module and use custom ARM asm imp instead.

#if defined(COMPILE_CLANG) && defined(COMPILE_ARM)
# define USE_GENERATED_ARM_ASM 1
#endif // SKIP __clang__ && ARM

// GCC 4.2 and newer seems to allocate registers in a way that breaks the inline
// arm asm in maxvid_decode.c, so use the ARM asm in this case.

#if defined(__GNUC__) && !defined(__clang__) && defined(COMPILE_ARM)
# define __GNUC_PREREQ(maj, min) \
  ((__GNUC__ << 16) + __GNUC_MINOR__ >= ((maj) << 16) + (min))
# if __GNUC_PREREQ(4,2)
#  define USE_GENERATED_ARM_ASM 1
# endif
#endif

// This inline asm flag would only be used if USE_GENERATED_ARM_ASM was not defined

#if defined(COMPILE_ARM)
# define USE_INLINE_ARM_ASM 1
#endif

// It is possible one might want to actually compile the C code on an
// ARM system and simply not use the inline ASM blocks and let the
// compiler generate ARM code automatically. Set the argument
// value for this if to 1 to enable build on ARM without inline ASM.

#if 0 && defined(USE_GENERATED_ARM_ASM)
#undef USE_GENERATED_ARM_ASM
#undef USE_INLINE_ARM_ASM
#endif


#if defined(USE_GENERATED_ARM_ASM)
	.section __TEXT,__text,regular
	.section __TEXT,__textcoal_nt,coalesced
	.section __TEXT,__const_coal,coalesced
	.section __TEXT,__picsymbolstub4,symbol_stubs,none,16
	.text
	.align 2
	.globl _maxvid_decode_c4_sample16
	.private_extern _maxvid_decode_c4_sample16
_maxvid_decode_c4_sample16:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, lr}
	add	r7, sp, #12
	stmfd	sp!, {r8, r10, r11}
	mov	r9, r1
	mov	r10, r0
	mov r8, #0
	
	mov r11, #1
	mvn r4, #0xC000
	orr r11, r11, r11, lsl #15
	mov r5, #2
	orr r5, r5, r11, lsr #1
	
	ldr r8, [r9], #4
	
	@ goto DECODE_16BPP

	b	L19
L3:
	@ DUP_16BPP
	
	tst r10, #3
	pkhbt r0, r8, r8, lsl #16
	subne ip, ip, #1
	strneh r8, [r10], #2
	
	mov lr, ip, lsr #1
	
	ldr r8, [r9], #4
	
	@ if (numWords > 6) goto DUPBIG_16BPP

	@ DUPSMALL_16BPP
	cmp	lr, #6
	bhi	L4
	mov r1, r0
	mov r2, r0
	cmp lr, #2
	stmgtia r10!, {r0, r1, r2}
	subgt lr, lr, #3
	cmp lr, #1
	stmgtia r10!, {r0, r1}
	tst lr, #0x1
	strne r0, [r10], #4
	
	tst ip, #1
	strneh r0, [r10], #2
	
	@ fall through to DECODE_16BPP
	
L19:
	@ DECODE_16BPP
	2:
	@ if ((opCode = (inW1 >> 30)) == SKIP) ...
	movs r6, r8, lsr #30
	addeq r10, r10, r8, lsl #1
	ldreq r8, [r9], #4
	beq 2b
	@ if (COPY1 == (inW1 >> 16)) ...
	cmp r11, r8, lsr #16
	streqh r8, [r10], #2
	ldreq r8, [r9], #4
	beq 2b
	@ if (DUP2 == (inW1 >> 16)) ...
	cmp r5, r8, lsr #16
	streqh r8, [r10], #2
	streqh r8, [r10], #2
	ldreq r8, [r9], #4
	beq 2b
	
	and ip, r4, r8, lsr #16
	
	@ Phantom assign to opCode
	
	@ if (opCode == DUP) goto DUP_16BPP
	
	cmp	r6, #1
	beq	L3
	@ Phantom assign to opCode
	
	@ if (opCode == DONE) goto DONE_16BPP
	
	cmp	r6, #3
	beq	L7

	@ COPY 16BPP

	@ align32
	tst r10, #3
	subne ip, ip, #1
	strneh r8, [r10], #2

	@ numWords
	mov lr, ip, lsr #1
  
	@ if (numWords > 7) goto COPYBIG_16BPP
	
	cmp	ip, #15
	bhi	L9
L10:
	@ COPYSMALL_16BPP

	cmp lr, #3
	ldmgtia r9!, {r0, r1, r2, r3}
	subgt lr, lr, #4
	stmgtia r10!, {r0, r1, r2, r3}
	cmp lr, #1
	ldmgtia r9!, {r0, r1}
	subgt lr, lr, #2
	stmgtia r10!, {r0, r1}
	cmp lr, #1
	ldreq r0, [r9], #4
	streq r0, [r10], #4
	
	tst ip, #0x1
	ldrne r3, [r9], #4
	strneh r3, [r10], #2
	
	ldr r8, [r9], #4
	
	@ goto DECODE_16BPP
	
	b	L19
L9:
	@ COPYBIG_16BPP

	@ Phantom assign to numWords
	
	cmp	lr, #31
	bls	L11
	and	r4, r9, #31
	rsb	r4, r4, #32
	mov	r4, r4, lsr #2
	and	r4, r4, #7
	sub lr, lr, r4
	cmp r4, #1
	ldmgtia r9!, {r2, r3}
	3:
	subgt r4, r4, #2
	stmgtia r10!, {r2, r3}
	cmp r4, #1
	ldmgtia r9!, {r2, r3}
	bgt 3b
	ldreq r2, [r9], #4
	streq r2, [r10], #4
	
L11:
	cmp	lr, #15
	bls	L13
	1:
	ldmia r9!, {r0, r1, r2, r3, r4, r5, r6, r8}
	pld	[r9, #32]
	sub lr, lr, #16
	stmia r10!, {r0, r1, r2, r3, r4, r5, r6, r8}
	ldmia r9!, {r0, r1, r2, r3, r4, r5, r6, r8}
	pld	[r9, #32]
	cmp lr, #15
	stmia r10!, {r0, r1, r2, r3, r4, r5, r6, r8}
	bgt 1b
	
L13:
	cmp lr, #7
	ldmgtia r9!, {r0, r1, r2, r3, r4, r5, r6, r8}
	subgt lr, lr, #8
	stmgtia r10!, {r0, r1, r2, r3, r4, r5, r6, r8}
	cmp lr, #3
	ldmgtia r9!, {r0, r1, r2, r3}
	subgt lr, lr, #4
	stmgtia r10!, {r0, r1, r2, r3}
	cmp lr, #1
	ldmgtia r9!, {r0, r1}
	subgt lr, lr, #2
	stmgtia r10!, {r0, r1}
	cmp lr, #1
	ldreq r0, [r9], #4
	streq r0, [r10], #4
	
	tst ip, #0x1
	ldrne r3, [r9], #4
	strneh r3, [r10], #2
	
	ldr r8, [r9], #4
	
	mov r5, #2
	mvn r4, #0xC000
	orr r5, r5, r11, lsr #1
	
	@ goto DECODE_16BPP
	
	b	L19
L4:
	@ DUPBIG_16BPP

	// align64 scheduled with r1 init
	tst r10, #7
	mov r1, r0
	strne r0, [r10], #4
	subne lr, lr, #1
	// end align64

	mov r2, r0
	mov r3, r0
	mov r4, r0
	mov r5, r0
	mov r6, r0
	mov r8, r0
	1:
	cmp lr, #7
	stmgtia r10!, {r0, r1, r2, r3, r4, r5, r6, r8}
	subgt lr, lr, #8
	bgt 1b
	cmp lr, #3
	subgt lr, lr, #4
	stmgtia r10!, {r0, r1, r2, r3}
	cmp lr, #2
	stmgtia r10!, {r0, r1, r2}
	stmeqia r10!, {r0, r1}
	cmp lr, #1
	streq r0, [r10], #4
	
	tst ip, #1
	strneh r0, [r10], #2
	
	ldr	r8, [r9, #-4]

  // FIXME: schedule constants in between cmp ops
	mov r5, #2
	mvn r4, #0xC000
	orr r5, r5, r11, lsr #1
	
	@ goto DECODE_16BPP
	
	b	L19
L7:
	@ DONE_16BPP
	
	mov	r0, #0
	ldmfd	sp!, {r8, r10, r11}
	ldmfd	sp!, {r4, r5, r6, r7, pc}





	.align 2
	.globl _maxvid_decode_c4_sample32
	.private_extern _maxvid_decode_c4_sample32
_maxvid_decode_c4_sample32:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, lr}
	add	r7, sp, #12
	stmfd	sp!, {r8, r10, r11}
	mov	r11, #0
	mov	r9, r1
	mov	r10, r0
	mov r8, #0
	mov lr, #0
	
	ldmia r9!, {r8, lr}
	
	mov r3, #1
	mov r4, #6
	mov r5, #9
	mov r6, #3
	
	@ goto DECODE_32BPP
	
	b	L39
L23:
	@ DUP_32BPP
	
	mov ip, r8, lsr #10
	
	mov r0, lr
	
	ldmia r9!, {r8, lr}
	
	@ if (numWords > 6) goto DUPBIG_32BPP

	// Note that the specific instruction order took a lot of work to get
	// right since optimal execution performance on Cortex A8 and A9 is
	// really tricky. The key to getting a speedup on both processors is
	// to do an unconditional add after the second stm and then use a
	// negative offset on the final conditional store without a writeback
	// so that the next instruction in the decode block is not waiting on r10.

	@ DUPSMALL_32BPP
	cmp	ip, #6
	bhi	L24

	mov r1, r0
	mov r2, r0

	// if (numWords >= 3) then write 3 words
	cmp ip, #2
	stmgt r10!, {r0, r1, r2}
	subgt ip, ip, #3

	// if (numWords >= 2) then write 2 words
	cmp ip, #1
	stmgt r10, {r0, r1}
	// frameBuffer32 += numPixels;
	add r10, r10, ip, lsl #2

	// if (numWords == 1 || numWords == 3) then write 1 word
	tst ip, #0x1
	strne r0, [r10, #-4]
	
	@ fall through to DECODE_32BPP
	
L39:
	@ DECODE_32BPP
	2:
	add r10, r10, r11, lsl #2
	and r11, r8, #0xFF
	cmp r4, r8, lsr #8
	streq lr, [r10], #4
	ldmeqia r9!, {r8, lr}
	beq 2b
	cmp r5, r8, lsr #8
	streq lr, [r10], #4
	streq lr, [r10], #4
	ldmeqia r9!, {r8, lr}
	beq 2b
	ands ip, r6, r8, lsr #8
	addeq r10, r10, r8, lsr #8
	moveq r8, lr
	ldreq lr, [r9], #4
	beq 2b
	
	@ Phantom assign to opCode
	
	@ if (opCode == DUP) goto DUP_32BPP
	
	cmp	ip, #1
	beq	L23
	@ Phantom assign to opCode
	
	@ if (opCode == DONE) goto DONE_32BPP
	
	cmp	ip, #3
	beq	L27
	str lr, [r10], #4
	rsb ip, r3, r8, lsr #10
	
	@ if (numWords > 7) goto COPYBIG_32BPP
	
	cmp	ip, #7
	bhi	L29
L30:
	@ COPYSMALL_32BPP
	
	cmp ip, #3
	ldmgtia r9!, {r0, r1, r2, r3}
	subgt ip, ip, #4
	stmgtia r10!, {r0, r1, r2, r3}
	cmp ip, #1
	ldmgtia r9!, {r0, r1}
	subgt ip, ip, #2
	stmgtia r10!, {r0, r1}
	cmp ip, #1
	ldreq r0, [r9], #4
	streq r0, [r10], #4
	
	ldmia r9!, {r8, lr}
	
	mov r3, #1
	
	@ goto DECODE_32BPP
	
	b	L39
L29:
	@ COPYBIG_32BPP
	
	@ Phantom assign to numPixels
	
	cmp	ip, #31
	bls	L31
	and	r4, r9, #31
	rsb	r4, r4, #32
	mov	r4, r4, lsr #2
	and	r4, r4, #7
	sub ip, ip, r4
	cmp r4, #1
	ldmgtia r9!, {r2, r3}
	3:
	subgt r4, r4, #2
	stmgtia r10!, {r2, r3}
	cmp r4, #1
	ldmgtia r9!, {r2, r3}
	bgt 3b
	ldreq r2, [r9], #4
	streq r2, [r10], #4
	
L31:
	cmp	ip, #15
	bls	L33
	1:
	ldmia r9!, {r0, r1, r2, r3, r4, r5, r6, r8}
	pld	[r9, #32]
	sub ip, ip, #16
	stmia r10!, {r0, r1, r2, r3, r4, r5, r6, r8}
	ldmia r9!, {r0, r1, r2, r3, r4, r5, r6, r8}
	pld	[r9, #32]
	cmp ip, #15
	stmia r10!, {r0, r1, r2, r3, r4, r5, r6, r8}
	bgt 1b
	
L33:
	cmp ip, #7
	ldmgtia r9!, {r0, r1, r2, r3, r4, r5, r6, r8}
	subgt ip, ip, #8
	stmgtia r10!, {r0, r1, r2, r3, r4, r5, r6, r8}
	cmp ip, #3
	ldmgtia r9!, {r0, r1, r2, r3}
	subgt ip, ip, #4
	stmgtia r10!, {r0, r1, r2, r3}
	cmp ip, #1
	ldmgtia r9!, {r0, r1}
	subgt ip, ip, #2
	stmgtia r10!, {r0, r1}
	cmp ip, #1
	ldreq r0, [r9], #4
	streq r0, [r10], #4
	
	ldmia r9!, {r8, lr}
	
	mov r3, #1
	mov r4, #6
	mov r5, #9
	mov r6, #3
	
	@ goto DECODE_32BPP
	
	b	L39
L24:
	@ DUPBIG_32BPP

	mov lr, r8

	// align64 scheduled with wr2 init
	tst r10, #7
	mov r1, r0
	strne r0, [r10], #4
	subne ip, ip, #1
	// end align64

	mov r2, r0
	mov r3, r0
	mov r4, r0
	mov r5, r0
	mov r6, r0
	mov r8, r0
1:
	cmp ip, #7
	stmgt r10!, {r0, r1, r2, r3, r4, r5, r6, r8}
	subgt ip, ip, #8
	bgt 1b
	cmp ip, #3
	subgt ip, ip, #4
	stmgt r10!, {r0, r1, r2, r3}
	cmp ip, #2
	stmgt r10!, {r0, r1, r2}
	stmeq r10!, {r0, r1}
	cmp ip, #1
	streq r0, [r10], #4
	
	mov r8, lr
	ldr lr, [r9, #-4]

  // FIXME: schedule constants in between cmp ops
	mov r3, #1
	mov r4, #6
	mov r5, #9
	mov r6, #3
	
	@ goto DECODE_32BPP
	
	b	L39
L27:
	@ DONE_32BPP
	
	mov	r0, #0
	ldmfd	sp!, {r8, r10, r11}
	ldmfd	sp!, {r4, r5, r6, r7, pc}

	.subsections_via_symbols

#else
  // No-op when USE_GENERATED_ARM_ASM is not defined
#endif
