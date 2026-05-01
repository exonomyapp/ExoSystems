#include "my_application.h"
#include <stdlib.h>

int main(int argc, char** argv) {
  // WORKAROUND: Bypass default GTK IM module and AT-SPI to prevent 5-10s DBus timeout freezing on TextField focus
  setenv("GTK_IM_MODULE", "none", 1);
  setenv("NO_AT_BRIDGE", "1", 1);
  
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
