#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>

#include <vector>

using namespace Rice;

TESTSUITE(Director);

namespace {
  /**
   * Abstract base class
   */
  class Worker
  {
    public:
      virtual ~Worker() = default;

      int getNumber() { return 12; }

      virtual int doSomething(int num) { return num * 4; }

      virtual int process(int num) = 0;
  };

  /**
   * Subclass that implements pure virtual
   */
  class MultiplyWorker : public Worker {
    public:
      virtual ~MultiplyWorker() { }

      virtual int process(int num) { return num * 2; }
  };

  /**
   * Class to handle workers
   */
  class Handler
  {
    std::vector<Worker*> mWorkers;

    public:

      void addWorker(Worker* worker)
      {
        mWorkers.push_back(worker);
      }

      int processWorkers(int start)
      {
        std::vector<Worker*>::iterator i = mWorkers.begin();
        int results = start;

        for(; i != mWorkers.end(); i++)
        {
          results = (*i)->process(results);
        }

        return results;
      }
  };

  /**
   * Our Director wrapper of Worker
   */
  class WorkerDirector : public Worker, public Rice::Director
  {
    public:
      WorkerDirector(Object self) : Director(self) { }

      virtual int process(int num)
      {
        return detail::From_Ruby<int>().convert( getSelf().call("process", num) );
      }

      int default_process(int num)
      {
        raisePureVirtual();
        return 0;
      }

      virtual int doSomething(int num)
      {
        return detail::From_Ruby<int>().convert( getSelf().call("do_something", num) );
      }

      int default_doSomething(int num)
      {
        return Worker::doSomething(num);
      }
  };
};

SETUP(Director)
{
  embed_ruby();
}

TESTCASE(exposes_worker_as_instantiatable_class)
{
  define_class<Worker>("Worker")
    .define_director<WorkerDirector>()
    .define_constructor(Constructor<WorkerDirector, Object>())
    .define_method("get_number", &Worker::getNumber);

  Module m = define_module("Testing");
  Object result = m.module_eval("worker = Worker.new; worker.get_number");

  ASSERT_EQUAL(12, detail::From_Ruby<int>().convert(result.value()));
}

TESTCASE(can_call_virtual_methods_on_base_class)
{
  define_class<Worker>("Worker")
    .define_director<WorkerDirector>()
    .define_constructor(Constructor<WorkerDirector, Object>())
    .define_method("get_number", &Worker::getNumber)
    .define_method("do_something", &WorkerDirector::default_doSomething);

  Module m = define_module("Testing");

  Object result = m.module_eval("worker = Worker.new; worker.do_something(4)");

  ASSERT_EQUAL(16, detail::From_Ruby<int>().convert(result.value()));
}

TESTCASE(super_calls_pass_execution_up_the_inheritance_chain)
{
  define_class<Worker>("Worker")
    .define_director<WorkerDirector>()
    .define_constructor(Constructor<WorkerDirector, Object>())
    .define_method("do_something", &WorkerDirector::default_doSomething);

  Module m = define_module("Testing");
  m.module_eval("class RubyWorker < Worker; def do_something(num); super * num; end; end");

  Object result = m.module_eval("worker = RubyWorker.new; worker.do_something(10)");

  ASSERT_EQUAL(400, detail::From_Ruby<int>().convert(result.value()));
}

TESTCASE(super_calls_on_pure_virtual_raise_error)
{
  define_class<Worker>("Worker")
    .define_director<WorkerDirector>()
    .define_constructor(Constructor<WorkerDirector, Object>())
    .define_method("process", &WorkerDirector::default_process);

  Module m = define_module("Testing");
  m.module_eval("class RubyWorker < Worker; def process(num); super; end; end");

  ASSERT_EXCEPTION_CHECK(
      Exception,
      m.module_eval("worker = RubyWorker.new; worker.process(10)"),
      ASSERT_EQUAL(
          Object(rb_eNotImpError),
          Object(CLASS_OF(ex.value()))
          )
      );
}

TESTCASE(polymorphic_calls_head_down_the_call_chain)
{
  define_class<Handler>("Handler")
    .define_constructor(Constructor<Handler>())
    .define_method("add_worker", &Handler::addWorker, Arg("worker").keepAlive())
    .define_method("process_workers", &Handler::processWorkers);

  define_class<Worker>("Worker")
    .define_director<WorkerDirector>()
    .define_constructor(Constructor<WorkerDirector, Object>())
    .define_method("process", &WorkerDirector::default_process);

  Module m = define_module("Testing");

  m.module_eval(
      "class EchoWorker < Worker; def process(num); num + 2; end; end;"
      "class DoubleWorker < Worker; def process(num); num * 2; end; end;"
      "$handler = Handler.new;"
      "$handler.add_worker(EchoWorker.new);"
      "$handler.add_worker(DoubleWorker.new);"
  );

  Object result = m.module_eval("$handler.process_workers(5)");

  // Hit's EchoWorker, so 5 + 2, then passes that to DoubleWorker, so 7 * 2 = 14
  ASSERT_EQUAL(14, detail::From_Ruby<int>().convert(result.value()));
}

namespace {

  class CallsSelf {
    public:
      virtual ~CallsSelf() { }

      int doIt(int in) {
        return doItImpl(in); 
      }

      virtual int doItImpl(int in) = 0;
  };

  class CallsSelfDirector : public CallsSelf, public Director
  {
    public:
      CallsSelfDirector(Object self) : Director(self) { }
      virtual ~CallsSelfDirector() { }

      virtual int doItImpl(int in)
      {
        return detail::From_Ruby<int>().convert( getSelf().call("do_it_impl", in) );
      }

      int default_doItImpl(int in)
      {
        raisePureVirtual();
        return 0;
      }
  };

  struct MyCallsSelf : CallsSelf
  {
    MyCallsSelf() { }
    virtual ~MyCallsSelf() { }

    int doItImpl(int in) { return in * 12; }
  };

  // Abstract type return types handled properly
  CallsSelf* getCallsSelf()
  {
    return new MyCallsSelf();
  }

  // Abstract type Argument types handled properly
  int doItOnPointer(CallsSelf* obj, int in)
  {
    return obj->doIt(in);
  }

  int doItOnReference(CallsSelf& obj, int in)
  {
    return obj.doIt(in);
  }
}

TESTCASE(mix_of_polymorphic_calls_and_inheritance_dont_cause_infinite_loops)
{
  define_class<CallsSelf>("CallsSelf")
    .define_director<CallsSelfDirector>()
    .define_constructor(Constructor<CallsSelfDirector, Rice::Object>())
    .define_method("do_it_impl", &CallsSelfDirector::default_doItImpl)
    .define_method("do_it", &CallsSelf::doIt);

  Module m = define_module("Testing");

  Object result = m.module_eval(
      "class MySelf < CallsSelf; def do_it_impl(num); num * 10; end; end;"
      "c = MySelf.new; c.do_it(10)"
      );

  ASSERT_EQUAL(100, detail::From_Ruby<int>().convert(result.value()));
}

TESTCASE(director_class_super_classes_get_type_bound)
{
  Module m = define_module("Testing");
  m.define_module_function("get_calls_self", &getCallsSelf);

  define_class<CallsSelf>("CallsSelf")
    .define_director<CallsSelfDirector>()
    .define_constructor(Constructor<CallsSelfDirector, Rice::Object>())
    .define_method("do_it_impl", &CallsSelfDirector::default_doItImpl)
    .define_method("do_it", &CallsSelf::doIt);

  Object result = m.module_eval(R"(cs = Testing::get_calls_self
                                     cs.do_it(3))");
  ASSERT_EQUAL(36, detail::From_Ruby<int>().convert(result.value()));
}

TESTCASE(director_allows_abstract_types_used_as_parameters_pointers)
{
  Module m = define_module("Testing");
  m.define_module_function("do_it_on_pointer", &doItOnPointer);

  define_class<CallsSelf>("CallsSelf")
    .define_director<CallsSelfDirector>()
    .define_constructor(Constructor<CallsSelfDirector, Rice::Object>())
    .define_method("do_it_impl", &CallsSelfDirector::default_doItImpl)
    .define_method("do_it", &CallsSelf::doIt);

  Object result = m.module_eval(
      "class MySelf < CallsSelf; def do_it_impl(num); num * 10; end; end;"
      "c = MySelf.new;"
      "Testing::do_it_on_pointer(c, 5)"
      );

  ASSERT_EQUAL(50, detail::From_Ruby<int>().convert(result.value()));
}

TESTCASE(director_allows_abstract_types_used_as_parameters_reference)
{
  Module m = define_module("Testing");
  m.define_module_function("do_it_on_ref", &doItOnReference);

  define_class<CallsSelf>("CallsSelf")
    .define_director<CallsSelfDirector>()
    .define_constructor(Constructor<CallsSelfDirector, Rice::Object>())
    .define_method("do_it_impl", &CallsSelfDirector::default_doItImpl)
    .define_method("do_it", &CallsSelf::doIt);

  Object result = m.module_eval(
      "class MySelf < CallsSelf; def do_it_impl(num); num * 10; end; end;"
      "c = MySelf.new;"
      "Testing::do_it_on_ref(c, 3)"
      );

  ASSERT_EQUAL(30, detail::From_Ruby<int>().convert(result.value()));
}