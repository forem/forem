#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>
#include <rice/stl.hpp>

using namespace Rice;

TESTSUITE(Keep_Alive);

namespace
{
  class Listener {
    public:
      virtual ~Listener() = default;
      virtual int getValue() { return 4; }
  };

  /**
   * This class will receive a new Listener instance
   * from Ruby
   */
  class ListenerContainer
  {
    public:
      void addListener(Listener* listener) 
      {
        mListeners.push_back(listener);
      }

      void removeListener(Listener* listener)
      {
        auto iter = std::find(mListeners.begin(), mListeners.end(), listener);
        mListeners.erase(iter);
      }

      int process()
      {
        std::vector<Listener*>::iterator i = mListeners.begin();
        int accum = 0;
        for(; i != mListeners.end(); i++)
        {
          accum += (*i)->getValue();
        }

        return accum;
      }

      size_t listenerCount()
      { 
        return mListeners.size();
      }

    private:
      std::vector<Listener*> mListeners;
  };
}

SETUP(Keep_Alive)
{
  embed_ruby();
}

TESTCASE(test_arg)
{
  define_class<Listener>("Listener")
    .define_constructor(Constructor<Listener>())
    .define_method("get_value", &Listener::getValue);

  define_class<ListenerContainer>("ListenerContainer")
    .define_constructor(Constructor<ListenerContainer>())
    .define_method("add_listener", &ListenerContainer::addListener, Arg("listener").keepAlive())
    .define_method("process", &ListenerContainer::process)
    .define_method("listener_count", &ListenerContainer::listenerCount);

  Module m = define_module("TestingModule");
  Object handler = m.module_eval("@handler = ListenerContainer.new");

  ASSERT_EQUAL(INT2NUM(0), handler.call("listener_count").value());

  m.module_eval(R"EOS(class MyListener < Listener
                        end)EOS");

  m.module_eval("@handler.add_listener(MyListener.new)");

  // Without keep alive, this GC will crash the program because MyListener is no longer in scope
  rb_gc_start();

  ASSERT_EQUAL(INT2NUM(1), handler.call("listener_count").value());
  ASSERT_EQUAL(INT2NUM(4), handler.call("process").value());

  // Without keep alive, this GC will crash the program because MyListener is no longer in scope
  rb_gc_start();
  m.module_eval("@handler.add_listener(Listener.new)");

  ASSERT_EQUAL(INT2NUM(2), handler.call("listener_count").value());
  ASSERT_EQUAL(INT2NUM(8), handler.call("process").value());
}

namespace
{
  class Connection; 

  class Column
  {
  public:
    Column(Connection& connection, uint32_t index) : connection_(connection), index_(index)
    {
    }

    std::string name();

  private:
    Connection& connection_;
    uint32_t index_;
  };

  class Connection
  {
  public:
    Column getColumn(uint32_t index)
    {
      return Column(*this, index);
    }

    std::string getName(uint32_t index)
    {
      return this->prefix_ + std::to_string(index);
    }

  private:
    std::string prefix_ = "column_";
  };

  std::string Column::name()
  {
    return this->connection_.getName(this->index_);
  }
}

Object getColumn(Module& m, uint32_t index)
{
  Object connection = m.module_eval("Connection.new");
  return connection.call("getColumn", 3);
}

TESTCASE(test_return)
{
  define_class<Column>("Column")
    .define_method("name", &Column::name);

  define_class<Connection>("Connection")
    .define_constructor(Constructor<Connection>())
    .define_method("getColumn", &Connection::getColumn, Return().keepAlive());

  Module m = define_module("TestingModule");

  Object column = getColumn(m, 3);
  rb_gc_start();
  String name = column.call("name");
  ASSERT_EQUAL("column_3", name.c_str());
}