/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_stack.h"

#define INITIAL_STACK_SIZE 16

// Creates a stack of prof_frame_t to keep track of timings for active methods.
prof_stack_t* prof_stack_create(void)
{
    prof_stack_t* stack = ALLOC(prof_stack_t);
    stack->start = ZALLOC_N(prof_frame_t, INITIAL_STACK_SIZE);
    stack->ptr = stack->start;
    stack->end = stack->start + INITIAL_STACK_SIZE;

    return stack;
}

void prof_stack_free(prof_stack_t* stack)
{
    xfree(stack->start);
    xfree(stack);
}

prof_frame_t* prof_stack_parent(prof_stack_t* stack)
{
    if (stack->ptr == stack->start || stack->ptr - 1 == stack->start)
        return NULL;
    else
        return stack->ptr - 2;
}

prof_frame_t* prof_stack_last(prof_stack_t* stack)
{
    if (stack->ptr == stack->start)
        return NULL;
    else
        return stack->ptr - 1;
}

void prof_stack_verify_size(prof_stack_t* stack)
{
    // Is there space on the stack?  If not, double its size.
    if (stack->ptr == stack->end)
    {
        size_t len = stack->ptr - stack->start;
        size_t new_capacity = (stack->end - stack->start) * 2;
        REALLOC_N(stack->start, prof_frame_t, new_capacity);

        /* Memory just got moved, reset pointers */
        stack->ptr = stack->start + len;
        stack->end = stack->start + new_capacity;
    }
}

prof_frame_t* prof_stack_push(prof_stack_t* stack)
{
    prof_stack_verify_size(stack);

    prof_frame_t* result = stack->ptr;
    stack->ptr++;
    return result;
}

prof_frame_t* prof_stack_pop(prof_stack_t* stack)
{
    prof_frame_t* result = prof_stack_last(stack);
    if (result)
        stack->ptr--;

    return result;
}

// ----------------  Frame Methods  ----------------------------
void prof_frame_pause(prof_frame_t* frame, double current_measurement)
{
    if (frame && prof_frame_is_unpaused(frame))
        frame->pause_time = current_measurement;
}

void prof_frame_unpause(prof_frame_t* frame, double current_measurement)
{
    if (prof_frame_is_paused(frame))
    {
        frame->dead_time += (current_measurement - frame->pause_time);
        frame->pause_time = -1;
    }
}

prof_frame_t* prof_frame_current(prof_stack_t* stack)
{
    return prof_stack_last(stack);
}

prof_frame_t* prof_frame_push(prof_stack_t* stack, prof_call_tree_t* call_tree, double measurement, bool paused)
{
    prof_frame_t* result = prof_stack_push(stack);
    prof_frame_t* parent_frame = prof_stack_parent(stack);

    result->call_tree = call_tree;

    result->start_time = measurement;
    result->pause_time = -1; // init as not paused.
    result->switch_time = 0;
    result->wait_time = 0;
    result->child_time = 0;
    result->dead_time = 0;
    result->source_file = Qnil;
    result->source_line = 0;

    call_tree->measurement->called++;
    call_tree->visits++;

    if (call_tree->method->visits > 0)
    {
        call_tree->method->recursive = true;
    }
    call_tree->method->measurement->called++;
    call_tree->method->visits++;

    // Unpause the parent frame, if it exists.
    // If currently paused then:
    //   1) The child frame will begin paused.
    //   2) The parent will inherit the child's dead time.
    if (parent_frame)
        prof_frame_unpause(parent_frame, measurement);

    if (paused)
    {
        prof_frame_pause(result, measurement);
    }

    // Return the result
    return result;
}

prof_frame_t* prof_frame_unshift(prof_stack_t* stack, prof_call_tree_t* parent_call_tree, prof_call_tree_t* call_tree, double measurement)
{
    if (prof_stack_last(stack))
        rb_raise(rb_eRuntimeError, "Stack unshift can only be called with an empty stack");

    parent_call_tree->measurement->total_time = call_tree->measurement->total_time;
    parent_call_tree->measurement->self_time = 0;
    parent_call_tree->measurement->wait_time = call_tree->measurement->wait_time;

    parent_call_tree->method->measurement->total_time += call_tree->measurement->total_time;
    parent_call_tree->method->measurement->wait_time += call_tree->measurement->wait_time;

    return prof_frame_push(stack, parent_call_tree, measurement, false);
}

prof_frame_t* prof_frame_pop(prof_stack_t* stack, double measurement)
{
    prof_frame_t* frame = prof_stack_pop(stack);

    if (!frame)
        return NULL;

    /* Calculate the total time this method took */
    prof_frame_unpause(frame, measurement);

    double total_time = measurement - frame->start_time - frame->dead_time;
    double self_time = total_time - frame->child_time - frame->wait_time;

    /* Update information about the current method */
    prof_call_tree_t* call_tree = frame->call_tree;

    // Update method measurement
    call_tree->method->measurement->self_time += self_time;
    call_tree->method->measurement->wait_time += frame->wait_time;
    if (call_tree->method->visits == 1)
        call_tree->method->measurement->total_time += total_time;

    call_tree->method->visits--;

    // Update method measurement
    call_tree->measurement->self_time += self_time;
    call_tree->measurement->wait_time += frame->wait_time;
    if (call_tree->visits == 1)
        call_tree->measurement->total_time += total_time;

    call_tree->visits--;

    prof_frame_t* parent_frame = prof_stack_last(stack);
    if (parent_frame)
    {
        parent_frame->child_time += total_time;
        parent_frame->dead_time += frame->dead_time;
    }

    frame->source_file = Qnil;

    return frame;
}

prof_method_t* prof_find_method(prof_stack_t* stack, VALUE source_file, int source_line)
{
    prof_frame_t* frame = prof_stack_last(stack);
    while (frame >= stack->start)
    {
        if (!frame->call_tree)
            return NULL;

        if (rb_str_equal(source_file, frame->call_tree->method->source_file) &&
            source_line >= frame->call_tree->method->source_line)
        {
            return frame->call_tree->method;
        }
        frame--;
    }
    return NULL;
}
