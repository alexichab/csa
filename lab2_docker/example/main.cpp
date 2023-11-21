#include <iostream>

int main(int argc, char **argv) {
  for(int i = 0; i < argc; ++i) {
    std::cout << "Argument " << i << ": " << argv[i] << '\n';
  }
  return 0;
}