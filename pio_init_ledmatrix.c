#include "ledmatrix.pio.h"

void pio_init_ledmatrix(PIO pio, int pin)
{
    uint offset = pio_add_program(pio, &ledmatrix_program);
    ledmatrix_program_init(pio, 0, offset, pin);
}