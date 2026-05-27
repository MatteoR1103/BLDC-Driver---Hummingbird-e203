// SPDX-License-Identifier: MIT
// High-level C API for the memory-mapped BLDC driver peripheral.

#ifndef BLDC_DRIVER_H
#define BLDC_DRIVER_H

#include <stdint.h>
#include "platform.h"

#define BLDC_REG_CFG_OFFSET        0x00u
#define BLDC_REG_TIMING_OFFSET     0x04u

#define BLDC_ENABLE_BIT            0u
#define BLDC_ENABLE_MASK           0x1u

#define BLDC_BRAKE_BIT             1u
#define BLDC_BRAKE_MASK            0x1u

#define BLDC_MODE_BIT              2u
#define BLDC_MODE_MASK             0x3u

#define BLDC_DIRECTION_BIT         4u
#define BLDC_DIRECTION_MASK        0x1u

#define BLDC_HALL_ABC_BIT          5u
#define BLDC_HALL_ABC_MASK         0x7u

#define BLDC_HALL_A_BIT            5u
#define BLDC_HALL_A_MASK           0x1u

#define BLDC_HALL_B_BIT            6u
#define BLDC_HALL_B_MASK           0x1u

#define BLDC_HALL_C_BIT            7u
#define BLDC_HALL_C_MASK           0x1u

#define BLDC_DEADZONE_BIT          12u
#define BLDC_DEADZONE_MASK         0xFu

#define BLDC_PERIOD_BIT            16u
#define BLDC_PERIOD_MASK           0xFFFFu

#define BLDC_TIME_1_BIT            0u
#define BLDC_TIME_1_MASK           0xFFFFu

#define BLDC_TIME_2_BIT            16u
#define BLDC_TIME_2_MASK           0xFFFFu

#define BLDC_MODE_STATIC           0u
#define BLDC_MODE_PWM              1u
#define BLDC_MODE_SPWM             2u

#define BLDC_DISABLE               0u
#define BLDC_ENABLE                1u

#define BLDC_DEFAULT_PERIOD        1200u
#define BLDC_DEFAULT_DEADZONE      2u

#define BLDC_DIRECTION_CCW         0u
#define BLDC_DIRECTION_CW          1u

typedef struct {
    uint8_t mode;
    uint8_t direction;
    uint16_t deadzone_ticks;
    uint16_t period_ticks;
    uint8_t duty_cycle;
    uint16_t acceleration;
} bldc_driver_t;

void bldc_write_field(uint32_t offset, uint32_t mask, uint8_t bit, uint32_t value);
void bldc_enable(void);
void bldc_disable(void);
uint8_t bldc_is_enabled(void);
uint8_t bldc_is_braking(void);
void bldc_set_deadzone(uint8_t deadzone_ticks);
void bldc_set_direction(uint8_t direction);
void bldc_set_static_motion(uint16_t period_ticks);
void bldc_set_pwm_motion(uint16_t period_ticks);
void bldc_set_pwm_duty(uint8_t duty_cycle);
void bldc_set_spwm_motion(uint16_t period_ticks);
void bldc_delay_ms(uint32_t milliseconds);
uint8_t bldc_read_hall_a(void);
uint8_t bldc_read_hall_b(void);
uint8_t bldc_read_hall_c(void);
void bldc_read_hall(uint8_t pins[3]);
uint8_t bldc_start(const bldc_driver_t *motor);
uint8_t bldc_soft_start(const bldc_driver_t *motor);
void bldc_tick(uint8_t count);

#endif
