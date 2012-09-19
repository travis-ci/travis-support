require 'active_record'
require 'active_record/connection_adapters/abstract_adapter'
require 'active_record/connection_adapters/postgresql_adapter'

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
  def next_sequence_value(sequence_name)
    Integer(select_value("SELECT NEXTVAL('#{sequence_name}')"))
  end
end

