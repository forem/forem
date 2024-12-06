#ifndef Rice__detail__Jump_Tag__hpp_
#define Rice__detail__Jump_Tag__hpp_

namespace Rice
{
  //! A placeholder for Ruby longjmp data.
  /*! When a Ruby exception is caught, the tag used for the longjmp is stored in
   *  a Jump_Tag, then later passed to rb_jump_tag() when there is no more
   *  C++ code to pass over.
   */
  struct Jump_Tag
  {
    //! Construct a Jump_Tag with tag t.
    Jump_Tag(int t) : tag(t) {}

    //! The tag being held.
    int tag;
  };
} // namespace Rice

#endif // Rice__detail__Jump_Tag__hpp_