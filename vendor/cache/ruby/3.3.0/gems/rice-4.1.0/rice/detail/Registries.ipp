namespace Rice::detail
{
  //Initialize static variables here.
  inline Registries Registries::instance;

  // TODO - Big hack here but this code is dependent on internals
  template<typename T>
  bool Type<T>::verify()
  {
    // Use intrinsic_type so that we don't have to define specializations
    // for pointers, references, const, etc.
    using Intrinsic_T = intrinsic_type<T>;

    if constexpr (std::is_fundamental_v<Intrinsic_T>)
    {
      return true;
    }
    else
    {
      return Registries::instance.types.verifyDefined<Intrinsic_T>();
    }
  }
}
