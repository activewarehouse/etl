module ETL #:nodoc:
  # Base class for transforms.
  #
  # A transform converts one value to another value using some sort of algorithm.
  #
  # A simple transform has two arguments, the field to transform and the name of the transform:
  #
  #   transform :ssn, :sha1
  #
  # Transforms can also be blocks:
  #
  #   transform(:ssn){ |v| v[0,24] }
  #
  # Finally, a transform can include a configuration hash:
  #
  #   transform :sex, :decode, {:decode_table_path => 'delimited_decode.txt'}
  class Transform
    autoload  :BlockTransform,              'etl/transform/block_transform'
    autoload  :CalculationTransform,        'etl/transform/calculation_transform'
    autoload  :DateToStringTransform,       'etl/transform/date_to_string_transform'
    autoload  :DecodeTransform,             'etl/transform/decode_transform'
    autoload  :DefaultTransform,            'etl/transform/default_transform'
    autoload  :ForeignKeyLookupTransform,   'etl/transform/foreign_key_lookup_transform'
    autoload  :HierarchyLookupTransform,    'etl/transform/hierarchy_lookup_transform'
    autoload  :Md5Transform,                'etl/transform/md5_transform'
    autoload  :OrdinalizeTransform,         'etl/transform/ordinalize_transform'
    autoload  :Sha1Transform,               'etl/transform/sha1_transform'
    autoload  :SplitFieldsTransform,        'etl/transform/split_fields_transform'
    autoload  :StringToDateTimeTransform,   'etl/transform/string_to_date_time_transform'
    autoload  :StringToDateTransform,       'etl/transform/string_to_date_transform'
    autoload  :StringToTimeTransform,       'etl/transform/string_to_time_transform'
    autoload  :TrimTransform,               'etl/transform/trim_transform'
    autoload  :TypeTransform,               'etl/transform/type_transform'

    class << self
      # Transform the specified value using the given transforms. The transforms can either be
      # Proc objects or objects which extend from Transform and implement the method <tt>transform(value)</tt>.
      # Any other object will result in a ControlError being raised.
      def transform(name, value, row, transforms)
        transforms.each do |transform|
          benchmarks[transform.class] ||= 0
          benchmarks[transform.class] += Benchmark.realtime do
            Engine.logger.debug "Transforming field #{name} with #{transform.inspect}"
            case transform
            when Proc
              value = transform.call([name, value, row])
            when Transform
              value = transform.transform(name, value, row)
            else
              raise ControlError, "Unsupported transform configuration type: #{transform}"
            end
          end
        end
        value
      end

      def benchmarks
        @benchmarks ||= {}
      end
    end

    attr_reader :control, :name, :configuration

    # Initialize the transform object with the given control object, field name and
    # configuration hash
    def initialize(control, name, configuration={})
      @control = control
      @name = name
      @configuration = configuration
    end

    def transform(name, value, row)
      raise "transform is an abstract method"
    end
  end
end
