#ifndef PIC_MODE_H_
#define PIC_MODE_H_

// A Macro that returns a static C string describing the PIC/PIE/static
// compilation mode for the current translation unit (object file).
#if defined(__PIE__) || defined(__pie__)
#define PIC_MODE_STRING  "pie"
#elif defined(__PIC__) || defined(__pic__)
#define PIC_MODE_STRING  "pic"
#else
#define PIC_MODE_STRING  "static"
#endif

// Return a static C string describing the compilation mode
// of this library. Value will depend on how the value is compiled by the
// build system.
extern const char* pic_mode_string();

#endif  // PIC_MODE_H_
