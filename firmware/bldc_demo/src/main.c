// SPDX-License-Identifier: MIT
// Demo firmware for the E203 BLDC motor-controller peripheral.

#include <stdint.h>
#include <platform.h>
#include "init.h"

#include "bsp/hbird-e200/drivers/bldc_driver/bldc_driver.h"

bldc_driver_t demo_motor;

int main(void)
{
    _init();

    demo_motor.mode = BLDC_MODE_STATIC;
    demo_motor.direction = BLDC_DIRECTION_CCW;
    demo_motor.period_ticks = 150;
    demo_motor.deadzone_ticks = 2;
    demo_motor.duty_cycle = 30;
    demo_motor.acceleration = 10;

    bldc_tick(3);
    bldc_delay_ms(150);
    bldc_tick(3);
    bldc_delay_ms(150);
    bldc_tick(3);
    bldc_delay_ms(400);

    bldc_tick(3);
    bldc_delay_ms(50);
    bldc_tick(3);
    bldc_delay_ms(50);
    bldc_tick(3);
    bldc_delay_ms(100);

    while(1)
    {
        while (bldc_read_hall_a()) {
        }

        demo_motor.direction = BLDC_DIRECTION_CCW;
        demo_motor.mode = BLDC_MODE_STATIC;
        bldc_soft_start(&demo_motor);
        bldc_delay_ms(20000);
        bldc_disable();
        bldc_delay_ms(5000);

        demo_motor.mode = BLDC_MODE_PWM;
        demo_motor.direction = BLDC_DIRECTION_CW;
        bldc_soft_start(&demo_motor);
        bldc_delay_ms(20000);
        bldc_disable();
        bldc_delay_ms(5000);

        demo_motor.mode = BLDC_MODE_SPWM;
        bldc_soft_start(&demo_motor);
        bldc_delay_ms(20000);
        bldc_disable();
    }
    return 0;
}
