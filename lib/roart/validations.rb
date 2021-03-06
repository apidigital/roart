module Roart
    
  class Errors
    include Enumerable
    
    def initialize(obj)
      @base, @errors = obj, {}
    end
    
    def add_to_base(msg)
      add(:base, msg)
    end
    
    def add(field, message)
      @errors[field.to_sym] ||= []
      @errors[field.to_sym] << message
    end
    
    def on_base
      on(:base)
    end
    
    def on(field)
      errors = @errors[field.to_sym]
      return nil if errors.nil?
      errors
    end
    
    alias :[] :on
    
    def each
      @errors.each_key { |attr| @errors[attr].each { |msg| yield attr, msg } }
    end
    
    # Returns true if no errors have been added.
    def empty?
      @errors.empty?
    end

    # Removes all errors that have been added.
    def clear
      @errors = {}
    end
    
    # Returns the total number of errors added. Two errors added to the same attribute will be counted as such.    
    def size
      @errors.values.inject(0) { |error_count, attribute| error_count + attribute.size }
    end
    
    alias_method :count, :size
    alias_method :length, :size
      
  end
  
  module Validations
    
    def self.included(model)
      model.extend ClassMethods

    end
  
    class Validators
      
      def initialize
        @validators = []
      end
      
      def add(validator)
        @validators << validator
      end
      
      def validate(obj)
        @validators.each{|validator| validator.call(obj)}
      end
      
    end
    
    module ClassMethods
      
      ALL_RANGE_OPTIONS = [ :is, :within, :in, :minimum, :min, :maximum, :max ].freeze
      ALL_NUMERICALITY_CHECKS = { :greater_than => '>', :greater_than_or_equal_to => '>=',
                                  :equal_to => '==', :less_than => '<', :less_than_or_equal_to => '<=',
                                  :odd => 'odd?', :even => 'even?' }.freeze

      def validator
        @validator ||= Validators.new
      end
      
      def validates_presence_of(*args)
        
      end
      
      def validates_format_of(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        args.each do |field|
          validator_proc = lambda do |obj|
            unless obj.send(field.to_sym).match(options[:format])
              obj.errors.add(field.to_sym, "Wrong Format") 
            end
          end
          self.validator.add(validator_proc)
        end
      end
      
      def validates_length_of(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        # Ensure that one and only one range option is specified.
        range_options = ALL_RANGE_OPTIONS & options.keys
        case range_options.size
        when 0
          raise ArgumentError, 'Range unspecified.  Specify the :within, :maximum, :minimum, or :is option.'
        when 1
          # Valid number of options; do nothing.
        else
          raise ArgumentError, 'Too many range options specified.  Choose only one.'
        end
        
        option = range_options.first
        option_value = options[range_options.first]
        key = {:is => :wrong_length, :minimum => :too_short, :maximum => :too_long}[option]
        custom_message = options[:message] || options[key]
        
        args.each do |field|
          case option
          when :within, :in
            raise ArgumentError, ":#{option} must be a Range" unless option_value.is_a?(Range)          
            validator_proc = lambda do |obj|
              if obj.send(field.to_sym).length < option_value.begin
                obj.errors.add(field.to_sym, "Must be more than #{option_value.begin} characters.") 
              end
              if obj.send(field.to_sym).length > option_value.end
                obj.errors.add(field.to_sym, "Must be less than #{option_value.end} characters")
              end
            end
            self.validator.add(validator_proc)
          when :min, :minium
            raise ArgumentError, ":#{option} must be an Integer" unless option_value.is_a?(Integer)
            validator_proc = lambda do |obj|
              if obj.send(field.to_sym).length < option_value
                obj.errors.add(field.to_sym, "Must be more than #{option_value} characters.") 
              end
            end
            self.validator.add(validator_proc)
          when :max, :maxium
            raise ArgumentError, ":#{option} must be an Integer" unless option_value.is_a?(Integer)
            validator_proc = lambda do |obj|
              if obj.send(field.to_sym).length > option_value
                obj.errors.add(field.to_sym, "Must be less than #{option_value} characters.") 
              end
            end
            self.validator.add(validator_proc)
          when :is
            raise ArgumentError, ":#{option} must be an Integer" unless option_value.is_a?(Integer)
            validator_proc = lambda do |obj|
              puts "#{field} is #{option_value}"
              unless obj.send(field.to_sym).length == option_value
                obj.errors.add(field.to_sym, "Must be #{option_value} characters.") 
              end
            end
            self.validator.add(validator_proc)
          end
        end
      end
      
      alias_method :validates_size_of, :validates_length_of
      
      def validates_numericality_of(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        numericality_options = ALL_NUMERICALITY_CHECKS & options.keys
        
        case numericality_options
        when 0
          raise ArgumentError, "Options Unspecified. Specify an option to use."
        when 1
          #continue
        else
          raise ArgumentError, "Too many options specified"
        end
        
        option = numericality_options.first
        option_value = options[numericality_options.first]
        key = {:is => :wrong_length, :minimum => :too_short, :maximum => :too_long}[option]
        custom_message = options[:message] || options[key]
        
        args.each do |field|
          numericality_options.each do |option|
            case option
              when :odd, :even
                unless raw_value.to_i.method(ALL_NUMERICALITY_CHECKS[option])[]
                  record.errors.add(attr_name, option, :value => raw_value, :default => configuration[:message]) 
                end
              else
                record.errors.add(attr_name, option, :default => configuration[:message], :value => raw_value, :count => configuration[option]) unless raw_value.method(ALL_NUMERICALITY_CHECKS[option])[configuration[option]]
            end
          end
        end
        
      end
      
    end
    
    def validator
      self.class.validator
    end
    
    def valid?
      validator.validate self
      self.errors.size == 0
    end
    
    def invalid?
      !valid?
    end
    
    def errors
      @errors ||= Errors.new(self)
    end
    
  end
    
end