/**
 * @file startup.s
 * @brief STM32F103 startup code and vector table
 * 
 * This file provides:
 * - Initial stack pointer
 * - Vector table with all exception/interrupt handlers
 * - Reset handler (system entry point)
 * - Default exception handlers (infinite loops)
 * - BSS and data section initialization
 */

    .syntax unified
    .cpu cortex-m3
    .thumb

    .global Reset_Handler
    .global _estack

/* Stack top - end of RAM */
_estack = 0x20010000  /* 64KB SRAM: 0x20000000 + 0x10000 */

/**
 * Vector Table
 * 
 * First entry: Initial stack pointer
 * Second entry: Reset handler (entry point)
 * Remaining entries: Exception and interrupt handlers
 * 
 * On reset, Cortex-M3:
 * 1. Loads SP from vector table[0]
 * 2. Loads PC from vector table[1] (Reset_Handler address)
 * 3. Begins execution
 */
    .section .isr_vector,"a",%progbits
    .word _estack              /* 0x00: Initial Stack Pointer */
    .word Reset_Handler        /* 0x04: Reset Handler */
    .word NMI_Handler          /* 0x08: NMI Handler */
    .word HardFault_Handler    /* 0x0C: Hard Fault Handler */
    .word MemManage_Handler    /* 0x10: MPU Fault Handler */
    .word BusFault_Handler     /* 0x14: Bus Fault Handler */
    .word UsageFault_Handler   /* 0x18: Usage Fault Handler */
    .word 0                    /* 0x1C: Reserved */
    .word 0                    /* 0x20: Reserved */
    .word 0                    /* 0x24: Reserved */
    .word 0                    /* 0x28: Reserved */
    .word SVC_Handler          /* 0x2C: SVCall Handler */
    .word DebugMon_Handler     /* 0x30: Debug Monitor Handler */
    .word 0                    /* 0x34: Reserved */
    .word PendSV_Handler       /* 0x38: PendSV Handler */
    .word SysTick_Handler      /* 0x3C: SysTick Handler */
    
    /* External interrupts (STM32F103 specific) */
    .word 0                    /* 0x40: WWDG */
    .word 0                    /* 0x44: PVD */
    .word 0                    /* 0x48: TAMPER */
    .word 0                    /* 0x4C: RTC */
    /* ... (60 more interrupt vectors for STM32F103) */
    /* Not critical for this application */

/**
 * Reset Handler
 * 
 * This is the first code executed after power-on or reset.
 * Responsibilities:
 * 1. Copy .data section from FLASH to RAM
 * 2. Zero .bss section in RAM
 * 3. Call SystemInit() if needed
 * 4. Call main()
 * 5. If main() returns, enter infinite loop
 */
    .section .text

    .thumb_func
Reset_Handler:
    /* Copy .data section from FLASH to SRAM */
    ldr r0, =_sdata       /* Destination start (RAM) */
    ldr r1, =_edata       /* Destination end (RAM) */
    ldr r2, =_sidata      /* Source start (FLASH) */
    movs r3, #0
    b data_init_check

data_init_loop:
    ldr r4, [r2, r3]      /* Load word from FLASH */
    str r4, [r0, r3]      /* Store word to RAM */
    adds r3, r3, #4       /* Next word */

data_init_check:
    adds r4, r0, r3       /* Current RAM address */
    cmp r4, r1            /* Check if done */
    bcc data_init_loop    /* Continue if not done */
    
    /* Zero .bss section */
    ldr r0, =_sbss        /* BSS start */
    ldr r1, =_ebss        /* BSS end */
    movs r2, #0           /* Zero value */
    b bss_init_check

bss_init_loop:
    str r2, [r0]          /* Write zero */
    adds r0, r0, #4       /* Next word */

bss_init_check:
    cmp r0, r1            /* Check if done */
    bcc bss_init_loop     /* Continue if not done */

    /* Call SystemInit (optional) */
    bl SystemInit
    
    /* Call main() */
    bl main
    
    /* Infinite loop if main returns (should never happen) */
1:  b 1b

/**
 * Default Exception Handlers
 * 
 * These are placeholders that halt execution.
 * In production, would implement proper handlers:
 * - HardFault: Log registers, reset
 * - SysTick: Increment tick counter
 * - etc.
 */

    .thumb_func
NMI_Handler:
    b .

    .thumb_func
HardFault_Handler:
    /* Debug: HardFault occurred */
    /* Could examine fault registers:
     * - SCB->HFSR (HardFault Status)
     * - SCB->CFSR (Configurable Fault Status)
     * - SCB->MMFAR (MemManage Address)
     * - SCB->BFAR (BusFault Address)
     */
    b .

    .thumb_func
MemManage_Handler:
    b .

    .thumb_func
BusFault_Handler:
    b .

    .thumb_func
UsageFault_Handler:
    b .

    .thumb_func
SVC_Handler:
    b .

    .thumb_func
DebugMon_Handler:
    b .

    .thumb_func
PendSV_Handler:
    b .

    .thumb_func
SysTick_Handler:
    /* Could increment tick counter here */
    bx lr  /* Return from interrupt */

    .end
