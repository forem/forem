#ifndef unittest__hpp_
#define unittest__hpp_

/*! \file
 *  \brief A (very) simple unit test framework.
 */

#if defined(_MSC_VER)
#define NOMINMAX
#endif

#include <vector>
#include <string>
#include <stdexcept>
#include <sstream>
#include <iostream>

class Failure
{
public:
  Failure(
      std::string const & test_suite_name,
      std::string const & test_case_name,
      std::string what)
    : test_suite_name_(test_suite_name)
    , test_case_name_(test_case_name)
    , what_(what)
  {
  }

  friend std::ostream & operator<<(std::ostream & out, Failure const & failure);

private:
  std::string test_suite_name_;
  std::string test_case_name_;
  std::string what_;
};

class Test_Result
{
public:
  void add_failure(Failure const & failure)
  {
    failures_.push_back(failure);
  }

  void add_error(Failure const & failure)
  {
    errors_.push_back(failure);
  }

  std::vector<Failure> const & failures() const
  {
    return failures_;
  }

  std::vector<Failure> const & errors() const
  {
    return errors_;
  }

private:
  std::vector<Failure> failures_;
  std::vector<Failure> errors_;
};

class Test_Case
{
public:
  typedef void (*Func)();

  Test_Case(
      std::string const & name,
      Func f)
    : name_(name)
    , f_(f)
  {
  }

  void run()
  {
    f_();
  }

  std::string const & name() const { return name_; }

  size_t size() const { return 1; }

private:
  std::string name_;
  Func f_;
};

class Test_Suite
{
public:
  Test_Suite(std::string const & name = "");

  void add_test_case(Test_Case const & test_case)
  {
    test_cases_.push_back(test_case);
  }

  void setup(void (*f)()) { setup_ = f; }
  void teardown(void (*f)()) { teardown_ = f; }

  void run(Test_Result & result);

  std::string const & name() const { return name_; }

  size_t size() const { return test_cases_.size(); }

private:
  std::string name_;

  typedef std::vector<Test_Case> Test_Cases;
  Test_Cases test_cases_;

  void (*setup_)();
  void (*teardown_)();
};


Test_Suite & test_suite();
void new_test_suite(std::string const & name);

class Assertion_Failed
  : public std::runtime_error
{
public:
  Assertion_Failed(std::string const & what)
    : std::runtime_error(what)
  {
  }
};


// TODO: not sure how to append __LINE__ correctly here
#define UNIQUE_SUITE_NAME(prefix, name) \
  prefix ## __ ## name \

#define TESTSUITE(name) \
  struct UNIQUE_SUITE_NAME(testsuite_append, name) \
  { \
    UNIQUE_SUITE_NAME(testsuite_append, name)() \
    { \
      new_test_suite(#name); \
    } \
  } UNIQUE_SUITE_NAME(testsuite_append__initializer, name)

#define TESTCASE(name) \
  static void UNIQUE_SUITE_NAME(test, name)(); \
  \
  namespace \
  { \
    struct UNIQUE_SUITE_NAME(test_append, name) \
    { \
      UNIQUE_SUITE_NAME(test_append, name)() \
      { \
        test_suite().add_test_case( \
            Test_Case(#name, & UNIQUE_SUITE_NAME(test, name))); \
      } \
    } UNIQUE_SUITE_NAME(test_append__initializer, name); \
  } \
  \
  static void UNIQUE_SUITE_NAME(test, name)()

#define TESTFIXTURE(name, type) \
  static void UNIQUE_SUITE_NAME(fixture ## __ ## name, type)(); \
  \
  namespace \
  { \
    struct UNIQUE_SUITE_NAME(fixture_append ## __ ## name, type) \
    { \
      UNIQUE_SUITE_NAME(fixture_append ## __ ## name, type)() \
      { \
        test_suite().type(UNIQUE_SUITE_NAME(fixture ## __ ## name, type)); \
      } \
    } UNIQUE_SUITE_NAME(fixture_append__initializer ## __ ## name, type); \
  } \
  \
  static void UNIQUE_SUITE_NAME(fixture ## __ ## name, type)()

#define SETUP(name) TESTFIXTURE(name, setup)

#define TEARDOWN(name) TESTFIXTURE(name, teardown)

template<typename RHS_T, typename LHS_T>
inline bool is_equal(RHS_T const & rhs, LHS_T const & lhs)
{
  return rhs == lhs;
}

inline bool is_equal(char const * lhs, char const * rhs)
{
  return std::string(lhs) == std::string(rhs);
}

inline bool is_equal(char * lhs, char const * rhs)
{
  return std::string(lhs) == std::string(rhs);
}

inline bool is_equal(char const * lhs, char * rhs)
{
  return std::string(lhs) == std::string(rhs);
}

template<typename T, typename U>
inline bool is_not_equal(T const & t, U const & u)
{
  return !is_equal(t, u);
}

extern size_t assertions;

template<typename S, typename T, typename = void>
struct is_streamable: std::false_type {};

template<typename S, typename T>
struct is_streamable<S, T, std::void_t<decltype(std::declval<S&>()<<std::declval<T>())>>: std::true_type {};

template<typename T, typename U>
void assert_equal(
    T const & t,
    U const & u,
    std::string const & s_t,
    std::string const & s_u,
    std::string const & file,
    size_t line)
{
  if(!is_equal(t, u))
  {
    std::stringstream strm;
    strm << "Assertion failed: ";

    if constexpr (is_streamable<std::stringstream, T>::value && is_streamable<std::stringstream, U>::value)
    {
      strm << s_t << " != " << s_u;
    }
    strm << " at " << file << ":" << line;
    throw Assertion_Failed(strm.str());
  }
}

template<typename T, typename U>
void assert_not_equal(
    T const & t,
    U const & u,
    std::string const & s_t,
    std::string const & s_u,
    std::string const & file,
    size_t line)
{
  if(!is_not_equal(t, u))
  {
    std::stringstream strm;
    strm << "Assertion failed: "
      << s_t << " should != " << s_u
      << " (" << t << " should != " << u << ")"
      << " at " << file << ":" << line;
    throw Assertion_Failed(strm.str());
  }
}

#define ASSERT_EQUAL(x, y) \
  do \
  { \
    ++assertions; \
    assert_equal((x), (y), #x, #y, __FILE__, __LINE__); \
  } while(0)

#define ASSERT_NOT_EQUAL(x, y) \
  do \
  { \
    ++assertions; \
    assert_not_equal((x), (y), #x, #y, __FILE__, __LINE__); \
  } while(0)

#define ASSERT(x) \
  ASSERT_EQUAL(true, !!x);

#define ASSERT_EXCEPTION_CHECK(type, code, check_exception) \
  try \
  { \
    ++assertions; \
    code; \
    ASSERT(!"Expected exception"); \
  } \
  catch(type const & ex) \
  { \
    check_exception; \
  }

#define ASSERT_EXCEPTION(type, code) \
  ASSERT_EXCEPTION_CHECK(type, code, )

#endif

