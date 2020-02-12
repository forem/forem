# raised when a model object tries to decorate itself,
# without having an inferrable decorator
class UninferrableDecoratorError < StandardError
end
