/*
 * Copyright 2023 Datadog, Inc
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Originally imported from https://github.com/DataDog/java-profiler/blob/11fe6206c31a14c6e5134e8401eaec8b22c618d7/ddprof-lib/src/main/cpp/pidController.cpp

#include "pid_controller.h"

#include <math.h>

inline static double computeAlpha(float cutoff) {
    if (cutoff <= 0)
        return 1;
    // α(fₙ) = cos(2πfₙ) - 1 + √( cos(2πfₙ)² - 4 cos(2πfₙ) + 3 )
    const double c = cos(2 * ((double) M_PI) * cutoff);
    return c - 1 + sqrt(c * c - 4 * c + 3);
}

void pid_controller_init(pid_controller *controller, u64 target_per_second, double proportional_gain, double integral_gain, double derivative_gain, int sampling_window, double cutoff_secs) {
    controller->_target = target_per_second * sampling_window;
    controller->_proportional_gain = proportional_gain;
    controller->_integral_gain = integral_gain * sampling_window;
    controller->_derivative_gain = derivative_gain / sampling_window;
    controller->_alpha = computeAlpha(sampling_window / cutoff_secs);
    controller->_avg_error= 0;
    controller->_integral_value = 0;
}

double pid_controller_compute(pid_controller *controller, u64 input, double time_delta_coefficient) {
    // time_delta_coefficient allows variable sampling window
    // the values are linearly scaled using that coefficient to reinterpret the given value within the expected sampling window
    double absolute_error = (((double) controller->_target) - ((double) input)) * time_delta_coefficient;

    double avg_error = (controller->_alpha * absolute_error) + ((1 - controller->_alpha) * controller->_avg_error);
    double derivative = avg_error - controller->_avg_error;

    // PID formula:
    // u[k] = Kp e[k] + Ki e_i[k] + Kd e_d[k], control signal
    double signal = controller->_proportional_gain * absolute_error + controller->_integral_gain * controller->_integral_value + controller->_derivative_gain * derivative;

    controller->_integral_value += absolute_error;
    controller->_avg_error = avg_error;

    return signal;
}
