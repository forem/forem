# raised when an object or collection tries to decorate itself,
# without having an inferrable decorator
class UninferrableDecoratorError < NameError
end
