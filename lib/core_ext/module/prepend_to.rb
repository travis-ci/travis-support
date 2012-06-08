require 'core_ext/module/include'

class Module
  def prepend_to(name, &definition)
    method = instance_method(name)
    remove_method(name) # to avoid warning
    define_method(name) do |*args, &block|
      definition.call(method.bind(self), *args, &block)
    end
  end
end
