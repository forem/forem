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

// Originally imported from https://github.com/DataDog/java-profiler/blob/11fe6206c31a14c6e5134e8401eaec8b22c618d7/ddprof-lib/src/main/cpp/pidController.h

#ifndef _PIDCONTROLLER_H
#define _PIDCONTROLLER_H

// From arch.h in java-profiler
typedef unsigned long long u64;

/*
 * A simple implementation of a PID controller.
 * Heavily influenced by https://tttapa.github.io/Pages/Arduino/Control-Theory/Motor-Fader/PID-Cpp-Implementation.html 
 */

typedef struct {
        u64 _target;
        double _proportional_gain;
        double _derivative_gain;
        double _integral_gain;
        double _alpha;

        double _avg_error;
        long long _integral_value;
} pid_controller;

void pid_controller_init(pid_controller *controller, u64 target_per_second, double proportional_gain, double integral_gain, double derivative_gain, int sampling_window, double cutoff_secs);
        
double pid_controller_compute(pid_controller *controller, u64 input, double time_delta_seconds);

#endif
