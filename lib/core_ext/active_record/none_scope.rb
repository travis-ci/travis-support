# will be added in rails 4, doing it more properly
# https://github.com/rails/rails/commit/75de1ce131cd39f68dbe6b68eecf2617a720a8e4
# for now we'll just limit to zero
ActiveRecord::Base.class_eval do
  def self.none
    limit(0)
  end
end


