class Module
  def with(*methods, &block)
    if methods.size > 1
      head = methods.shift
      with(*methods) { send(head, &block) }
    else
      send(methods.first, &block)
    end
  end
end
