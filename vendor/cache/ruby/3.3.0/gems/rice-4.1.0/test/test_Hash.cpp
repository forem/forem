#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>

#include <vector>
#include <map>
#include <algorithm>

using namespace Rice;

TESTSUITE(Hash);

SETUP(Hash)
{
  embed_ruby();
}

TESTCASE(default_construct)
{
  Hash h;
  ASSERT_EQUAL(T_HASH, rb_type(h));
  ASSERT_EQUAL(0u, RHASH_SIZE(h.value()));
}

TESTCASE(construct_from_object)
{
  Object o(rb_hash_new());
  Hash h(o);
  ASSERT_EQUAL(T_HASH, rb_type(h));
  ASSERT_EQUAL(0u, RHASH_SIZE(h.value()));
}

TESTCASE(construct_from_value)
{
  VALUE v(rb_hash_new());
  Hash h(v);
  ASSERT_EQUAL(T_HASH, rb_type(h));
  ASSERT_EQUAL(0u, RHASH_SIZE(h.value()));
}

TESTCASE(copy_construct)
{
  Hash h;
  Hash h2(h);
  ASSERT_EQUAL(h.value(), h2.value());
}

TESTCASE(assignment)
{
  Hash h;
  Hash h2;
  h = h2;
  ASSERT_EQUAL(h.value(), h2.value());
}

TESTCASE(size)
{
  Hash h;
  ASSERT_EQUAL(0u, h.size());
  h[1] = 5;
  ASSERT_EQUAL(1u, h.size());
  h[6] = 9;
  ASSERT_EQUAL(2u, h.size());
  h[42] = 42;
  ASSERT_EQUAL(3u, h.size());
  h[6] = 1;
  ASSERT_EQUAL(3u, h.size());
}

TESTCASE(bracket)
{
  Hash h;
  h[1] = 5;
  h[6] = 9;
  h[42] = 42;
  h[6] = 1;
  ASSERT_EQUAL(detail::to_ruby(5), h[1].value());
  ASSERT_EQUAL(detail::to_ruby(42), h[42].value());
  ASSERT_EQUAL(detail::to_ruby(1), h[6].value());
}

TESTCASE(get)
{
  Hash h;
  h[1] = 5;
  h[6] = 9;
  h[42] = 42;
  h[6] = 1;
  ASSERT_EQUAL(5, h.get<int>(1));
  ASSERT_EQUAL(42, h.get<int>(42));
  ASSERT_EQUAL(1, h.get<int>(6));
}

TESTCASE(construct_vector_from_hash_iterators)
{
  Hash h;
  h[1] = 5;
  h[6] = 9;
  h[42] = 42;
  h[6] = 1;

  std::vector<Hash::Entry> v(h.begin(), h.end());
  std::sort(v.begin(), v.end());
  ASSERT_EQUAL(3u, v.size());
  ASSERT_EQUAL(v[0].key.value(), detail::to_ruby(1));
  ASSERT_EQUAL(v[1].key.value(), detail::to_ruby(6));
  ASSERT_EQUAL(v[2].key.value(), detail::to_ruby(42));
  ASSERT_EQUAL(&v[0].key, &v[0].first);
  ASSERT_EQUAL(&v[1].key, &v[1].first);
  ASSERT_EQUAL(&v[2].key, &v[2].first);
  ASSERT_EQUAL(v[0].value, detail::to_ruby(5));
  ASSERT_EQUAL(v[1].value, detail::to_ruby(1));
  ASSERT_EQUAL(v[2].value, detail::to_ruby(42));
  ASSERT_EQUAL(&v[0].value, &v[0].second);
  ASSERT_EQUAL(&v[1].value, &v[1].second);
  ASSERT_EQUAL(&v[2].value, &v[2].second);
}

TESTCASE(iterate)
{
  Hash h;
  h[1] = 5;
  h[6] = 9;
  h[42] = 42;
  h[6] = 1;

  std::vector<Hash::Entry> v;
  Hash::iterator it = h.begin();
  Hash::iterator end = h.end();

  for(; it != end; ++it)
  {
    v.push_back(*it);
  }

  std::sort(v.begin(), v.end());
  ASSERT_EQUAL(3u, v.size());
  ASSERT_EQUAL(v[0].key.value(), detail::to_ruby(1));
  ASSERT_EQUAL(v[1].key.value(), detail::to_ruby(6));
  ASSERT_EQUAL(v[2].key.value(), detail::to_ruby(42));
  ASSERT_EQUAL(&v[0].key, &v[0].first);
  ASSERT_EQUAL(&v[1].key, &v[1].first);
  ASSERT_EQUAL(&v[2].key, &v[2].first);
  ASSERT_EQUAL(v[0].value, detail::to_ruby(5));
  ASSERT_EQUAL(v[1].value, detail::to_ruby(1));
  ASSERT_EQUAL(v[2].value, detail::to_ruby(42));
  ASSERT_EQUAL(&v[0].value, &v[0].second);
  ASSERT_EQUAL(&v[1].value, &v[1].second);
  ASSERT_EQUAL(&v[2].value, &v[2].second);
}

TESTCASE(const_iterate)
{
  Hash h;
  h[1] = 5;
  h[6] = 9;
  h[42] = 42;
  h[6] = 1;
  std::vector<Hash::Entry> v;
  Hash::const_iterator it = h.begin();
  Hash::const_iterator end = h.end();
  for(; it != end; ++it)
  {
    v.push_back(*it);
  }
  std::sort(v.begin(), v.end());
  ASSERT_EQUAL(3u, v.size());
  ASSERT_EQUAL(v[0].key.value(), detail::to_ruby(1));
  ASSERT_EQUAL(v[1].key.value(), detail::to_ruby(6));
  ASSERT_EQUAL(v[2].key.value(), detail::to_ruby(42));
  ASSERT_EQUAL(&v[0].key, &v[0].first);
  ASSERT_EQUAL(&v[1].key, &v[1].first);
  ASSERT_EQUAL(&v[2].key, &v[2].first);
  ASSERT_EQUAL(v[0].value.value(), detail::to_ruby(5));
  ASSERT_EQUAL(v[1].value.value(), detail::to_ruby(1));
  ASSERT_EQUAL(v[2].value.value(), detail::to_ruby(42));
  ASSERT_EQUAL(&v[0].value, &v[0].value);
  ASSERT_EQUAL(&v[1].value, &v[1].value);
  ASSERT_EQUAL(&v[2].value, &v[2].value);
}

TESTCASE(iterate_and_change)
{
  Hash h;
  h[1] = 5;
  h[6] = 9;
  h[42] = 42;
  h[6] = 1;
  Hash::const_iterator it = h.begin();
  Hash::const_iterator end = h.end();
  std::map<int, int> m;
  for(int j = 0; it != end; ++j, ++it)
  {
    it->second = j;
    m[detail::From_Ruby<int>().convert(it->first)] = j;
  }
  ASSERT_EQUAL(3u, m.size());
  ASSERT_EQUAL(detail::to_ruby(m[1]), h[1]);
  ASSERT_EQUAL(detail::to_ruby(m[6]), h[6]);
  ASSERT_EQUAL(detail::to_ruby(m[42]), h[42]);
}

/**
 * Issue 59 - Copy constructor compilation problem.
 */

namespace {
  void testHashArg(Object self, Hash string) {
  }
}

TESTCASE(use_hash_in_wrapped_function) {
  define_global_function("test_hash_arg", &testHashArg);
}
