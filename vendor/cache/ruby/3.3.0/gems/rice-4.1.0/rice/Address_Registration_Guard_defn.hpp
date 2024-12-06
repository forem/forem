#ifndef Rice__Address_Registration_Guard_defn__hpp_
#define Rice__Address_Registration_Guard_defn__hpp_

#include "cpp_api/Object_defn.hpp"
#include "detail/ruby.hpp"

namespace Rice
{
  //! A guard to register a given address with the GC.
  /*! Calls rb_gc_register_address upon construction and
   *  rb_gc_unregister_address upon destruction.
   *  For example:
   *  \code
   *    Class Foo
   *    {
   *    public:
   *      Foo()
   *        : string_(rb_str_new2())
   *        , guard_(&string_);
   *
   *    private:
   *      VALUE string_;
   *      Address_Registration_Guard guard_;
   *    };
   *  \endcode
   */
  class Address_Registration_Guard
  {
  public:
    //! Register an address with the GC.
    /*  \param address The address to register with the GC.  The address
     *  must point to a valid ruby object (RObject).
     */
    Address_Registration_Guard(VALUE* address);

    //! Register an Object with the GC.
    /*! \param object The Object to register with the GC.  The object must
     *  not be destroyed before the Address_Registration_Guard is
     *  destroyed.
     */
    Address_Registration_Guard(Object* object);

    //! Unregister an address/Object with the GC.
    /*! Destruct an Address_Registration_Guard.  The address registered
     *  with the Address_Registration_Guard when it was constructed will
     *  be unregistered from the GC.
     */
    ~Address_Registration_Guard();

    // Disable copying
    Address_Registration_Guard(Address_Registration_Guard const& other) = delete;
    Address_Registration_Guard& operator=(Address_Registration_Guard const& other) = delete;

    // Enable moving
    Address_Registration_Guard(Address_Registration_Guard&& other);
    Address_Registration_Guard& operator=(Address_Registration_Guard&& other);

    //! Get the address that is registered with the GC.
    VALUE* address() const;

    /** Called during Ruby's exit process since we should not call
     * rb_gc unregister_address there
     */
    static void disable();

  private:
    inline static bool enabled = true;
    inline static bool exit_handler_registered = false;
    static void registerExitHandler();

  private:
    void registerAddress() const;
    void unregisterAddress();

    VALUE* address_ = nullptr;
  };
} // namespace Rice

#endif // Rice__Address_Registration_Guard_defn__hpp_