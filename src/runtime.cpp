/**
 * @file runtime.cpp
 * @brief Minimal C++ runtime for bare-metal systems
 * 
 * Provides: pure virtual handler, delete operators, guard variables for static init
 */

#include <cstddef>
#include <cstdint>

/**
 * @brief Pure virtual function call handler
 * 
 * This function is called if a pure virtual function is called.
 * This should never happen in correct code, but the compiler
 * requires this symbol to exist.
 */
extern "C" void __cxa_pure_virtual() {
    while (1) {}
}


/// Delete operator (no-op - no dynamic allocation)
void operator delete(void* ptr) noexcept {
    (void)ptr;
    // Could halt here to catch accidental delete calls:
    // while (1) {}
}

/**
 * @brief Sized global delete operator (C++14)
 * @param ptr Pointer to memory to free
 * @param size Size of memory being freed
 * 
 * C++14 added sized delete operators for optimization.
 * Same as regular delete for our purposes.
 */
void operator delete(void* ptr, std::size_t size) noexcept {
    (void)ptr;
    (void)size;
    // No-op
}


/// Array delete operator (no-op)
void operator delete[](void* ptr) noexcept {
    (void)ptr;
}

/// Sized array delete operator (no-op)
void operator delete[](void* ptr, std::size_t size) noexcept {
    (void)ptr;
    (void)size;
}

// Note: new operator intentionally not implemented (no dynamic allocation)

/// Acquire lock for static initialization (check if init needed)
extern "C" int __cxa_guard_acquire(uint64_t* guard) {
    return !*(char*)guard;
}

/// Release lock after successful initialization
extern "C" void __cxa_guard_release(uint64_t* guard) {
    *(char*)guard = 1;
}

/// Abort initialization (exceptions not used)
extern "C" void __cxa_guard_abort(uint64_t* guard) {
    (void)guard;
}


// Constructor/destructor support
typedef void (*func_ptr)();

extern func_ptr __preinit_array_start[];
extern func_ptr __preinit_array_end[];
extern func_ptr __init_array_start[];
extern func_ptr __init_array_end[];
extern func_ptr __fini_array_start[];
extern func_ptr __fini_array_end[];

/// Call global constructors
extern "C" void __libc_init_array() {
    for (func_ptr* func = __preinit_array_start; func < __preinit_array_end; func++) {
        (*func)();
    }
    for (func_ptr* func = __init_array_start; func < __init_array_end; func++) {
        (*func)();
    }
}

/// Call global destructors
extern "C" void __libc_fini_array() {
    for (func_ptr* func = __fini_array_start; func < __fini_array_end; func++) {
        (*func)();
    }
}

// Newlib stubs (prevent linker errors)
extern "C" {

void* _sbrk(int incr) {
    (void)incr;
    return nullptr;
}

int _close(int file) {
    (void)file;
    return -1;
}

int _fstat(int file, void* st) {
    (void)file;
    (void)st;
    return -1;
}

int _isatty(int file) {
    (void)file;
    return 0;
}

int _lseek(int file, int offset, int whence) {
    (void)file;
    (void)offset;
    (void)whence;
    return -1;
}

int _read(int file, char* ptr, int len) {
    (void)file;
    (void)ptr;
    (void)len;
    return 0;
}

int _write(int file, const char* ptr, int len) {
    (void)file;
    (void)ptr;
    (void)len;
    return len;
}

void _exit(int status) {
    (void)status;
    while (1) {}
}

int _kill(int pid, int sig) {
    (void)pid;
    (void)sig;
    return -1;
}

int _getpid() {
    return 1;
}

}
