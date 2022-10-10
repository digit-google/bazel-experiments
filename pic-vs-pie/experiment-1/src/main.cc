#include <stdio.h>

#include "pic_mode.h"

int main(int argc, char* argv[]) {
  printf("executable mode: %s, library mode: %s\n", PIC_MODE_STRING, pic_mode_string());
  return 0;
}
