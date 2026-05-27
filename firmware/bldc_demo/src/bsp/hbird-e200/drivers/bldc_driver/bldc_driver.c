// SPDX-License-Identifier: MIT
// High-level C API for the memory-mapped BLDC driver peripheral.

#include "bldc_driver.h"

static uint32_t bldc_read_reg(uint32_t offset)
{
    return BLDC_DRIVER_REG(offset);
}

void bldc_write_field(uint32_t offset, uint32_t mask, uint8_t bit, uint32_t value)
{
    uint32_t reg_value = bldc_read_reg(offset);
    reg_value &= ~(mask << bit);
    reg_value |= ((value & mask) << bit);
    BLDC_DRIVER_REG(offset) = reg_value;
}

void bldc_enable(void)
{
    bldc_write_field(BLDC_REG_CFG_OFFSET, BLDC_ENABLE_MASK, BLDC_ENABLE_BIT, BLDC_ENABLE);
}

void bldc_disable(void)
{
    bldc_write_field(BLDC_REG_CFG_OFFSET, BLDC_ENABLE_MASK, BLDC_ENABLE_BIT, BLDC_DISABLE);
}

uint8_t bldc_is_enabled(void)
{
    return (uint8_t)((bldc_read_reg(BLDC_REG_CFG_OFFSET) >> BLDC_ENABLE_BIT) & BLDC_ENABLE_MASK);
}

uint8_t bldc_is_braking(void)
{
    return (uint8_t)((bldc_read_reg(BLDC_REG_CFG_OFFSET) >> BLDC_BRAKE_BIT) & BLDC_BRAKE_MASK);
}

void bldc_set_deadzone(uint8_t deadzone_ticks)
{
    if (deadzone_ticks > BLDC_DEADZONE_MASK) {
        deadzone_ticks = BLDC_DEADZONE_MASK;
    }

    if (deadzone_ticks < BLDC_DEFAULT_DEADZONE) {
        deadzone_ticks = BLDC_DEFAULT_DEADZONE;
    }

    bldc_write_field(BLDC_REG_CFG_OFFSET, BLDC_DEADZONE_MASK, BLDC_DEADZONE_BIT, deadzone_ticks);
}

void bldc_set_direction(uint8_t direction)
{
    if (!bldc_is_enabled()) {
        bldc_write_field(
            BLDC_REG_CFG_OFFSET,
            BLDC_DIRECTION_MASK,
            BLDC_DIRECTION_BIT,
            direction ? BLDC_DIRECTION_CW : BLDC_DIRECTION_CCW
        );
    }
}

void bldc_set_static_motion(uint16_t period_ticks)
{
    bldc_write_field(BLDC_REG_CFG_OFFSET, BLDC_MODE_MASK, BLDC_MODE_BIT, BLDC_MODE_STATIC);
    bldc_write_field(BLDC_REG_CFG_OFFSET, BLDC_PERIOD_MASK, BLDC_PERIOD_BIT, period_ticks);
    bldc_write_field(BLDC_REG_TIMING_OFFSET, BLDC_TIME_2_MASK, BLDC_TIME_2_BIT, period_ticks / 3u);
}

void bldc_set_pwm_motion(uint16_t period_ticks)
{
    bldc_write_field(BLDC_REG_CFG_OFFSET, BLDC_MODE_MASK, BLDC_MODE_BIT, BLDC_MODE_PWM);
    bldc_write_field(BLDC_REG_CFG_OFFSET, BLDC_PERIOD_MASK, BLDC_PERIOD_BIT, period_ticks);
    bldc_write_field(BLDC_REG_TIMING_OFFSET, BLDC_TIME_2_MASK, BLDC_TIME_2_BIT, period_ticks / 3u);
    bldc_write_field(BLDC_REG_TIMING_OFFSET, BLDC_TIME_1_MASK, BLDC_TIME_1_BIT, 0u);
}

void bldc_set_pwm_duty(uint8_t duty_cycle)
{
    uint32_t mode = (bldc_read_reg(BLDC_REG_CFG_OFFSET) >> BLDC_MODE_BIT) & BLDC_MODE_MASK;

    if (mode == BLDC_MODE_PWM) {
        uint32_t period = (bldc_read_reg(BLDC_REG_CFG_OFFSET) >> BLDC_PERIOD_BIT) & BLDC_PERIOD_MASK;
        bldc_write_field(
            BLDC_REG_TIMING_OFFSET,
            BLDC_TIME_1_MASK,
            BLDC_TIME_1_BIT,
            (period * duty_cycle) / 300u
        );
    }
}

void bldc_set_spwm_motion(uint16_t period_ticks)
{
    bldc_write_field(BLDC_REG_CFG_OFFSET, BLDC_MODE_MASK, BLDC_MODE_BIT, BLDC_MODE_SPWM);
    bldc_write_field(BLDC_REG_CFG_OFFSET, BLDC_PERIOD_MASK, BLDC_PERIOD_BIT, period_ticks);
    bldc_write_field(BLDC_REG_TIMING_OFFSET, BLDC_TIME_1_MASK, BLDC_TIME_1_BIT, period_ticks / 3u);
    bldc_write_field(BLDC_REG_TIMING_OFFSET, BLDC_TIME_2_MASK, BLDC_TIME_2_BIT, period_ticks / 3u);
}

#pragma GCC push_options
#pragma GCC optimize("O0")
void bldc_delay_ms(uint32_t milliseconds)
{
    for (uint32_t i = 0; i < milliseconds; i++) {
        for (uint32_t j = 0; j < 787u; j++) {
            __asm__ volatile ("nop");
        }
    }
}
#pragma GCC pop_options

uint8_t bldc_read_hall_a(void)
{
    return (uint8_t)((bldc_read_reg(BLDC_REG_CFG_OFFSET) >> BLDC_HALL_A_BIT) & BLDC_HALL_A_MASK);
}

uint8_t bldc_read_hall_b(void)
{
    return (uint8_t)((bldc_read_reg(BLDC_REG_CFG_OFFSET) >> BLDC_HALL_B_BIT) & BLDC_HALL_B_MASK);
}

uint8_t bldc_read_hall_c(void)
{
    return (uint8_t)((bldc_read_reg(BLDC_REG_CFG_OFFSET) >> BLDC_HALL_C_BIT) & BLDC_HALL_C_MASK);
}

void bldc_read_hall(uint8_t pins[3])
{
    uint8_t hall = (uint8_t)((bldc_read_reg(BLDC_REG_CFG_OFFSET) >> BLDC_HALL_ABC_BIT) & BLDC_HALL_ABC_MASK);

    pins[0] = hall & 0x1u;
    pins[1] = (hall >> 1) & 0x1u;
    pins[2] = (hall >> 2) & 0x1u;
}

uint8_t bldc_start(const bldc_driver_t *motor)
{
    if (motor == 0) {
        return 0u;
    }

    if ((motor->direction != BLDC_DIRECTION_CCW) && (motor->direction != BLDC_DIRECTION_CW)) {
        return 0u;
    }

    if (motor->duty_cycle > 100u) {
        return 0u;
    }

    bldc_set_direction(motor->direction);
    bldc_set_deadzone((uint8_t)motor->deadzone_ticks);

    if (motor->mode == BLDC_MODE_STATIC) {
        bldc_set_static_motion(motor->period_ticks);
    } else if (motor->mode == BLDC_MODE_PWM) {
        bldc_set_pwm_motion(motor->period_ticks);
        bldc_set_pwm_duty(motor->duty_cycle);
    } else if (motor->mode == BLDC_MODE_SPWM) {
        bldc_set_spwm_motion(motor->period_ticks);
    } else {
        return 0u;
    }

    bldc_enable();
    return 1u;
}

uint8_t bldc_soft_start(const bldc_driver_t *motor)
{
    uint16_t startup_period = 600u;
    uint16_t target_period;
    uint16_t step;

    if (motor == 0) {
        return 0u;
    }

    if ((motor->direction != BLDC_DIRECTION_CCW) && (motor->direction != BLDC_DIRECTION_CW)) {
        return 0u;
    }

    if (motor->duty_cycle > 100u) {
        return 0u;
    }

    target_period = motor->period_ticks;
    step = motor->acceleration * 3u;

    if (step == 0u) {
        step = 1u;
    } else if (step > 90u) {
        step = 90u;
    }

    bldc_set_direction(motor->direction);
    bldc_set_deadzone((uint8_t)motor->deadzone_ticks);

    if ((motor->mode == BLDC_MODE_STATIC) || (motor->mode == BLDC_MODE_SPWM)) {
        bldc_set_static_motion(startup_period);
    } else if (motor->mode == BLDC_MODE_PWM) {
        bldc_set_pwm_motion(startup_period);
    } else {
        return 0u;
    }

    bldc_enable();

    while (startup_period > target_period) {
        bldc_delay_ms(350u);

        if (!bldc_is_enabled()) {
            break;
        }

        if ((startup_period - target_period) <= step) {
            startup_period = target_period;
        } else {
            startup_period -= step;
        }

        bldc_write_field(BLDC_REG_CFG_OFFSET, BLDC_PERIOD_MASK, BLDC_PERIOD_BIT, startup_period);
        bldc_write_field(BLDC_REG_TIMING_OFFSET, BLDC_TIME_2_MASK, BLDC_TIME_2_BIT, startup_period / 3u);

        if (motor->mode == BLDC_MODE_PWM) {
            bldc_write_field(
                BLDC_REG_TIMING_OFFSET,
                BLDC_TIME_1_MASK,
                BLDC_TIME_1_BIT,
                (startup_period * motor->duty_cycle) / 300u
            );
        }
    }

    if (motor->mode == BLDC_MODE_SPWM) {
        bldc_delay_ms(500u);
        bldc_disable();
        bldc_set_spwm_motion(target_period);
        bldc_enable();
    }

    return 1u;
}

void bldc_tick(uint8_t count)
{
    uint8_t direction = BLDC_DIRECTION_CCW;

    for (uint8_t i = 0; i < count; i++) {
        bldc_set_static_motion(60u);
        bldc_set_direction(direction);
        bldc_enable();
        bldc_delay_ms(10u);
        bldc_disable();
        bldc_delay_ms(10u);
        direction = !direction;
    }
}
