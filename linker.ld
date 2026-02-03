/**
 * Linker Script for STM32F103 (256KB Flash, 64KB RAM)
 * 
 * This script defines:
 * - Memory regions (FLASH and RAM)
 * - Section placement (.text, .data, .bss, etc.)
 * - Symbol definitions for startup code
 * 
 * Memory Layout:
 * FLASH: 0x08000000 - 0x0803FFFF (256KB)
 * RAM:   0x20000000 - 0x2000FFFF (64KB)
 * 
 * Sections:
 * .isr_vector → FLASH @ 0x08000000 (vector table must be first!)
 * .text       → FLASH (code and read-only data)
 * .data       → RAM, initialized from FLASH
 * .bss        → RAM, zero-initialized
 */

/* Entry point for debugger */
ENTRY(Reset_Handler)

/**
 * Memory Regions
 * 
 * STM32F103 memory map:
 * - FLASH starts at 0x08000000 (aliased to 0x00000000 after boot)
 * - SRAM starts at 0x20000000
 * 
 * Permissions:
 * - r = readable
 * - w = writable
 * - x = executable
 */
MEMORY
{
    /* 
     * FLASH (256KB)
     * - Read-only after programming
     * - Executable (code)
     * - Non-volatile (data persists across power cycles)
     */
    FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 256K
    
    /*
     * RAM (64KB)
     * - Read-write
     * - Executable (allows RAM code if needed, e.g., flash programming)
     * - Volatile (data lost on power cycle)
     */
    RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 64K
}

/**
 * Section Definitions
 * 
 * Sections are blocks of code/data with specific purposes:
 * .isr_vector = interrupt vector table
 * .text = code and read-only data
 * .data = initialized global/static variables
 * .bss = zero-initialized global/static variables
 */
SECTIONS
{
    /**
     * Vector Table (.isr_vector)
     * 
     * MUST be first section in FLASH at address 0x08000000
     * Cortex-M3 loads initial SP and PC from first 8 bytes
     * 
     * KEEP() prevents linker from removing it even if "unused"
     */
    .isr_vector :
    {
        . = ALIGN(4);  /* Ensure 4-byte alignment */
        KEEP(*(.isr_vector))  /* Keep vector table */
        . = ALIGN(4);
    } > FLASH

    /**
     * Code and Read-Only Data (.text, .rodata)
     * 
     * Contains:
     * - Executable code (.text sections)
     * - Constant data (.rodata sections)
     * - Exception handling tables (.eh_frame)
     * - Constructor/destructor lists (.init_array, .fini_array)
     * 
     * Located in FLASH (read-only memory)
     */
    .text :
    {
        . = ALIGN(4);
        
        /* Code */
        *(.text)           /* Normal code */
        *(.text*)          /* Code in named sections (.text.foo) */
        
        /* Read-only data */
        *(.rodata)         /* Const data */
        *(.rodata*)        /* Const data in named sections */
        
        /* C++ static constructor/destructor lists */
        . = ALIGN(4);
        PROVIDE_HIDDEN(__preinit_array_start = .);
        KEEP(*(.preinit_array))
        PROVIDE_HIDDEN(__preinit_array_end = .);
        
        . = ALIGN(4);
        PROVIDE_HIDDEN(__init_array_start = .);
        KEEP(*(SORT(.init_array.*)))
        KEEP(*(.init_array))
        PROVIDE_HIDDEN(__init_array_end = .);
        
        . = ALIGN(4);
        PROVIDE_HIDDEN(__fini_array_start = .);
        KEEP(*(SORT(.fini_array.*)))
        KEEP(*(.fini_array))
        PROVIDE_HIDDEN(__fini_array_end = .);
        
        /* Exception handling (usually not used in bare-metal) */
        *(.eh_frame)
        
        . = ALIGN(4);
        _etext = .;  /* End of .text section */
    } > FLASH

    /**
     * Initialized Data (.data)
     * 
     * Contains global/static variables with initial values.
     * 
     * Strategy:
     * - Initial values stored in FLASH (read-only)
     * - Data copied to RAM during startup
     * - Code accesses RAM copy (allows modification)
     * 
     * AT() specifies FLASH load address
     * VMA (virtual address) is in RAM
     * LMA (load address) is in FLASH
     */
    _sidata = LOADADDR(.data);  /* Source address in FLASH */
    
    .data : AT(_sidata)
    {
        . = ALIGN(4);
        _sdata = .;  /* Start of .data in RAM */
        
        *(.data)     /* Initialized data */
        *(.data*)    /* Initialized data in named sections */
        
        . = ALIGN(4);
        _edata = .;  /* End of .data in RAM */
    } > RAM

    /**
     * Zero-Initialized Data (.bss)
     * 
     * Contains global/static variables initialized to zero.
     * 
     * Strategy:
     * - No initial values stored in FLASH (waste of space)
     * - Startup code writes zeros to this section
     * - Located in RAM only
     * 
     * Why separate from .data?
     * - Saves FLASH space (no need to store zeros)
     * - .bss can be huge without affecting binary size
     */
    .bss :
    {
        . = ALIGN(4);
        _sbss = .;   /* Start of .bss */
        
        *(.bss)      /* Zero-initialized data */
        *(.bss*)     /* Zero-initialized data in named sections */
        *(COMMON)    /* Common symbols (legacy) */
        
        . = ALIGN(4);
        _ebss = .;   /* End of .bss */
    } > RAM

    /**
     * Heap (optional, not used in our application)
     * 
     * If using dynamic allocation (malloc/new), heap would go here.
     * We don't use it, but defining symbols prevents linker errors.
     */
    .heap :
    {
        . = ALIGN(8);
        PROVIDE(end = .);
        PROVIDE(_end = .);
        PROVIDE(__heap_start = .);
        . = . + 0;  /* No heap space allocated */
        PROVIDE(__heap_end = .);
    } > RAM

    /**
     * Stack
     * 
     * Stack grows downward from end of RAM.
     * _estack symbol (defined in startup.s) points to RAM end.
     * 
     * No explicit section needed - just use remaining RAM.
     * Could add stack overflow detection by reserving space:
     * 
     * .stack :
     * {
     *     . = . + 4096;  // Reserve 4KB for stack
     *     _estack = .;
     * } > RAM
     */

    /**
     * Debug Sections (not loaded to target)
     * 
     * These sections contain debugging information for GDB.
     * They're not loaded to the microcontroller, only used by debugger.
     */
    .debug_info     0 : { *(.debug_info) }
    .debug_abbrev   0 : { *(.debug_abbrev) }
    .debug_line     0 : { *(.debug_line) }
    .debug_str      0 : { *(.debug_str) }
    .debug_frame    0 : { *(.debug_frame) }
    .debug_loc      0 : { *(.debug_loc) }
    .debug_ranges   0 : { *(.debug_ranges) }
    
    /**
     * Discard unwanted sections
     * 
     * /DISCARD/ removes these sections entirely:
     * - .ARM.exidx: Exception index (not used)
     * - .ARM.extab: Exception table (not used)
     * - .comment: Compiler comments (not needed in binary)
     */
    /DISCARD/ :
    {
        *(.ARM.exidx*)
        *(.ARM.extab*)
        *(.comment)
    }
}

/**
 * Size Checking (optional)
 * 
 * Could add assertions to ensure sections fit in memory:
 * ASSERT(_edata < ORIGIN(RAM) + LENGTH(RAM), "Data overflow")
 * ASSERT(_ebss < ORIGIN(RAM) + LENGTH(RAM), "BSS overflow")
 */
