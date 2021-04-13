#include "lib1/hellolib.h"
#include "foohello.h"
#include <iostream>

int main() {
  std::cout << "Hello from main.cc" << std::endl;
  foo_hello();
  lib_hello();
  return 0;
}
