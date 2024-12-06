#include <assert.h> 

#include "unittest.hpp"
#include "embed_ruby.hpp"

#include <rice/rice.hpp>
#include <rice/stl.hpp>

using namespace Rice;

TESTSUITE(Inheritance);

namespace
{
  enum class NotificationType
  {
    Email,
    Push
  };

  class Notification
  {
  public:
    virtual ~Notification() = default;
    virtual std::string message() = 0;
  };

  class EmailNotification : public Notification
  {
    std::string message() override
    {
      return "Email";
    }
  };

  class PushNotification : public Notification
  {
    std::string message() override
    {
      return "Push";
    }
  };

  Notification* makeNotification(NotificationType type)
  {
    switch (type)
    {
    case NotificationType::Email:
      return new EmailNotification();
      break;

    case NotificationType::Push:
      return new PushNotification();

    default:
      return nullptr; // Will never happen but makes compiler happy
    }
  }

  std::string processNotification(Notification* notification)
  {
    return notification->message();
  }
}

Enum<NotificationType> createNotificationEnum()
{
  return define_enum<NotificationType>("NotificationType")
    .define_value("Email", NotificationType::Email)
    .define_value("Push", NotificationType::Push);
}

SETUP(Inheritance)
{
  embed_ruby();
  static Enum<NotificationType> NotificationEnum = createNotificationEnum();

  Data_Type<Notification>::unbind();
  Data_Type<EmailNotification>::unbind();
  Data_Type<PushNotification>::unbind();
}

TESTCASE(return_base_pointer)
{
  Class rcNotification = define_class<Notification>("Notification");

  Class rcEmailNotification = define_class<EmailNotification, Notification>("EmailNotification")
    .define_constructor(Constructor<PushNotification>());

  Class rcPushNotification = define_class<PushNotification, Notification>("PushNotification")
    .define_constructor(Constructor<PushNotification>());

  define_global_function("make_notification", &makeNotification);

  Module m = define_module("Testing");

  Object notification = m.module_eval("make_notification(NotificationType::Email)");
  String temp = notification.class_of().name();
  std::string temp2 = detail::From_Ruby<std::string>().convert(temp);

  ASSERT(rb_obj_is_kind_of(notification, rcNotification));
  ASSERT(rb_obj_is_kind_of(notification, rcEmailNotification));
  ASSERT(!rb_obj_is_kind_of(notification, rcPushNotification));
  ASSERT(rb_obj_is_instance_of(notification, rcEmailNotification));

  notification = m.module_eval("make_notification(NotificationType::Push)");
  ASSERT(rb_obj_is_kind_of(notification, rcNotification));
  ASSERT(!rb_obj_is_kind_of(notification, rcEmailNotification));
  ASSERT(rb_obj_is_kind_of(notification, rcPushNotification));
  ASSERT(rb_obj_is_instance_of(notification, rcPushNotification));
}

TESTCASE(base_pointer_method_call)
{
  Class rcNotification = define_class<Notification>("Notification")
    .define_method("message", &Notification::message);

  Class rcEmailNotification = define_class<EmailNotification, Notification>("EmailNotification")
    .define_constructor(Constructor<EmailNotification>());

  Class rcPushNotification = define_class<PushNotification, Notification>("PushNotification")
    .define_constructor(Constructor<PushNotification>());

  Module m = define_module("Testing");

  Object message = m.module_eval(R"EOS(notification = EmailNotification.new
                                         notification.message)EOS");
  ASSERT_EQUAL("Email", detail::From_Ruby<std::string>().convert(message));

  message = m.module_eval(R"EOS(notification = PushNotification.new
                                  notification.message)EOS");
  ASSERT_EQUAL("Push", detail::From_Ruby<std::string>().convert(message));
}

TESTCASE(base_pointer_function_argument)
{
  Class rcNotification = define_class<Notification>("Notification")
    .define_method("message", &Notification::message);

  Class rcEmailNotification = define_class<EmailNotification, Notification>("EmailNotification")
    .define_constructor(Constructor<EmailNotification>());

  Class rcPushNotification = define_class<PushNotification, Notification>("PushNotification")
    .define_constructor(Constructor<PushNotification>());

  define_global_function("process_notification", &processNotification);

  Module m = define_module("Testing");
  Object message = m.module_eval(R"EOS(notification = EmailNotification.new
                                         process_notification(notification))EOS");
  ASSERT_EQUAL("Email", detail::From_Ruby<std::string>().convert(message));

  message = m.module_eval(R"EOS(notification = PushNotification.new
                                  process_notification(notification))EOS");
  ASSERT_EQUAL("Push", detail::From_Ruby<std::string>().convert(message));
}

TESTCASE(module_base_pointer_method_call)
{
  Module mInheritance = define_module("Inheritance");

  Class rcNotification = define_class_under<Notification>(mInheritance, "Notification")
    .define_method("message", &Notification::message);

  Class rcEmailNotification = define_class_under<EmailNotification, Notification>(mInheritance, "EmailNotification")
    .define_constructor(Constructor<EmailNotification>());

  Class rcPushNotification = define_class_under<PushNotification, Notification>(mInheritance, "PushNotification")
    .define_constructor(Constructor<PushNotification>());

  Module m = define_module("Testing");

  Object message = m.module_eval(R"EOS(notification = Inheritance::EmailNotification.new
                                         notification.message)EOS");
  ASSERT_EQUAL("Email", detail::From_Ruby<std::string>().convert(message));

  message = m.module_eval(R"EOS(notification = Inheritance::PushNotification.new
                                  notification.message)EOS");
  ASSERT_EQUAL("Push", detail::From_Ruby<std::string>().convert(message));
}

namespace
{
  class Processor
  {
  public:
    Processor(Notification* notification) : notification_(notification)
    {
    }

    std::string process()
    {
      return notification_->message();
    }

  private:
    Notification* notification_;
  };
}

TESTCASE(base_pointer_constructor)
{
  Class rcNotification = define_class<Notification>("Notification");

  Class rcEmailNotification = define_class<EmailNotification, Notification>("EmailNotification")
    .define_constructor(Constructor<PushNotification>());

  Class rcPushNotification = define_class<PushNotification, Notification>("PushNotification")
    .define_constructor(Constructor<PushNotification>());

  Class rcProcessor = define_class<Processor, Notification>("Processor")
    .define_constructor(Constructor<Processor, Notification*>())
    .define_method("process", &Processor::process);

  Module m = define_module("Testing");

  Object result = m.module_eval(R"EOS(notification = PushNotification.new
                                        processor = Processor.new(notification)
                                        processor.process)EOS");
  ASSERT_EQUAL("Push", detail::From_Ruby<std::string>().convert(result));
}