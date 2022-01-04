Dummy::Application.routes.draw do
  TestController.actions.each do |action|
    get action, to: ['test', action].join('#')
  end
end
