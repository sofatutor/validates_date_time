module ActiveRecord::Validations::DateTime
  def self.append_features(base)
    super
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def validates_date(*attr_names)
      configuration = { :message        => "is an invalid date",
                        :before         => Proc.new { 1.year.from_now.to_date },
                        :before_message => "must be before",
                        :after          => Proc.new { Date.new(1900, 1, 1) },
                        :after_message  => "must be after",
                        :on => :save }
      configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)
      
      validates_each(attr_names, configuration) do |record, attr_name, value|
        value_before_type_cast = record.send("#{attr_name}_before_type_cast")
        
        if result = parse_date_string(value_before_type_cast.to_s)
          if configuration[:before]
            before = configuration[:before].call
            record.errors.add(attr_name, "#{configuration[:before_message]} #{before}") if result > before
          end
          
          if configuration[:after]
            after = configuration[:after].call
            record.errors.add(attr_name, "#{configuration[:after_message]} #{after}") if result < after
          end                
            
          record.send("#{attr_name}=", result) unless record.errors.on(attr_name)
        else
          record.errors.add(attr_name, configuration[:message])
        end
      end
    end
    
    def validates_time(*attr_names)
      configuration = { :message => "is an invalid time", :on => :save }
      configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)
      
      validates_each(attr_names, configuration) do |record, attr_name, value|
        value_before_type_cast = record.send("#{attr_name}_before_type_cast")
        
        unless value_before_type_cast.is_a?(Time)
          result = parse_time_string(value_before_type_cast.to_s)
          record.send("#{attr_name}=", result)
          record.errors.add(attr_name, configuration[:message]) unless result
        end 
      end        
    end
    
   private
    # Attempt to parse a string into a Date object.
    # Return nil if parsing fails
    def parse_date_string(string)
      return if string.nil?
      
      string = case string.strip
        # 22/1/06
        when /^(\d{1,2})[\\\/\.:-](\d{1,2})[\\\/\.:-](\d{2}|\d{4})$/
          "#{ unambiguous_year $3 }-#{$2}-#{$1}"
          
        # 22 Feb 06 or 1 jun 2001
        when /^(\d{1,2}) (\w{3}) (\d{2}|\d{4})$/
          "#{ unambiguous_year $3 }-#{ Date::ABBR_MONTHNAMES.index($2.capitalize) }-#{$1}"
        
        # 2006-01-01, ignored
        when /^\d{4}-\d{2}-\d{2}$/
          string
        
        # Not a valid date string
        else
          return
      end
      
      Date.new(*string.split('-').collect { |s| s.to_i }) rescue nil
    end
    
    # Attempt to parse a string into a Time object.
    # Return nil if parsing fails
    def parse_time_string(string)
      return if string.nil?
      
      string = case string.strip
        # 12 hour with minute: 7.30pm, 11:20am, 2 20PM
        when /^(\d{1,2})[\. :](\d{2})\s?(am|pm)$/i
          "#{ $3.downcase == 'pm' ? $1.to_i + 12 : $1 }-#{$2}"
        
        # 12 hour without minute: 2pm, 11Am, 7 pm
        when /^(\d{1,2})\s?(am|pm)$/i
          "#{ $2.downcase == 'pm' ? $1.to_i + 12 : $1 }-0"
        
        # 24 hour: 22:30, 03.10, 12 30
        when /^(\d{2})[\. :](\d{2})$/
          "#{$1}-#{$2}"
          
        # Empty time is invalid
        when /00:00:00/
          return
	  
        # HH:MM:SS
        when /^(\d{2}):(\d{2}):(\d{2})$/
          string
        
        else
          return
      end
      
      time_array = [2000, 1, 1, *string.split('-').collect { |s| s.to_i }]
      Time.send(ActiveRecord::Base.default_timezone, *time_array) rescue nil
    end
    
    # Extract a 4-digit year from a 2-digit year.
    # If the number is less than 20, assume year 20#{number}
    # otherwise use 19#{number}. Ignore if already 4 digits.
    #
    # Eg:
    #    10 => 2010, 60 => 1960, 00 => 2000, 1963 => 1963
    def unambiguous_year(year)
      year.length == 2 ? (year.to_i < 20 ? "20#{year}" : "19#{year}") : year
    end
  end
end
