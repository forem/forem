#include <rice/rice.hpp>

using namespace Rice;

class Organism
{
public:
  virtual ~Organism() = default;
  virtual char const * name() = 0;
};

class Animal
  : public Organism
{
public:
  virtual char const * speak() = 0;
};

class Bear
  : public Animal
{
public:
  char const * name() override
  {
    return "Bear";
  }

  char const * speak() override
  {
    return "I'm smarter than the average bear";
  }
};

class Dog
  : public Animal
{
public:
  char const * name() override
  {
    return "Dog";
  }

  char const * speak() override
  {
    return "Woof woof";
  }
};

class Rabbit
  : public Animal
{
public:
  char const * name() override
  {
    return "Rabbit";
  }

  char const * speak() override
  {
    return "What's up, doc?";
  }
};

extern "C"
void Init_animals(void)
{
    define_class<Organism>("Organism")
      .define_method("name", &Organism::name);

    define_class<Animal, Organism>("Animal")
      .define_method("speak", &Animal::speak);

    define_class<Bear, Animal>("Bear")
      .define_constructor(Constructor<Bear>());
      
    define_class<Dog, Animal>("Dog")
      .define_constructor(Constructor<Dog>());

    define_class<Rabbit, Animal>("Rabbit")
      .define_constructor(Constructor<Rabbit>());
}

