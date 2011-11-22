# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module Inclusion
      # Adds a criterion to the +Criteria+ that specifies values that must all
      # be matched in order to return results. Similar to an "in" clause but the
      # underlying conditional logic is an "AND" and not an "OR". The MongoDB
      # conditional operator that will be used is "$all".
      #
      # Options:
      #
      # attributes: A +Hash+ where the key is the field name and the value is an
      # +Array+ of values that must all match.
      #
      # Example:
      #
      # <tt>criteria.all(:field => ["value1", "value2"])</tt>
      #
      # <tt>criteria.all(:field1 => ["value1", "value2"], :field2 => ["value1"])</tt>
      #
      # Returns: <tt>self</tt>
      def all(attributes = {})
        update_selector(attributes, "$all")
      end
      alias :all_in :all

      # Adds a criterion to the +Criteria+ that specifies values that must
      # be matched in order to return results. This is similar to a SQL "WHERE"
      # clause. This is the actual selector that will be provided to MongoDB,
      # similar to the Javascript object that is used when performing a find()
      # in the MongoDB console.
      #
      # Options:
      #
      # selectior: A +Hash+ that must match the attributes of the +Document+.
      #
      # Example:
      #
      # <tt>criteria.and(:field1 => "value1", :field2 => 15)</tt>
      #
      # Returns: <tt>self</tt>
      def and(selector = nil)
        where(selector)
      end

      # Adds a criterion to the +Criteria+ that specifies a set of expressions
      # to match if any of them return true. This is a $or query in MongoDB and
      # is similar to a SQL OR. This is named #any_of and aliased "or" for
      # readability.
      #
      # @example Adding the criterion.
      #   criteria.any_of({ :field1 => "value" }, { :field2 => "value2" })
      #
      # @param [ Array<Hash> ] args A list of name/value pairs any can match.
      #
      # @return [ Criteria ] A new criteria with the added selector.
      def any_of(*args)
        clone.tap do |crit|
          criterion = @selector["$or"] || []
          converted = BSON::ObjectId.convert(klass, args.flatten)
          expanded = converted.collect(&:expand_complex_criteria)
          crit.selector["$or"] = criterion.concat(expanded)
        end
      end
      alias :or :any_of

      # Adds a criterion to the +Criteria+ that specifies values where any can
      # be matched in order to return results. This is similar to an SQL "IN"
      # clause. The MongoDB conditional operator that will be used is "$in".
      #
      # Options:
      #
      # attributes: A +Hash+ where the key is the field name and the value is an
      # +Array+ of values that any can match.
      #
      # Example:
      #
      # <tt>criteria.in(:field => ["value1", "value2"])</tt>
      #
      # <tt>criteria.in(:field1 => ["value1", "value2"], :field2 => ["value1"])</tt>
      #
      # Returns: <tt>self</tt>
      def in(attributes = {})
        update_selector(attributes, "$in")
      end
      alias :any_in :in

      # Adds a criterion to the +Criteria+ that specifies values to do
      # geospacial searches by. The field must be indexed with the "2d" option.
      #
      # Options:
      #
      # attributes: A +Hash+ where the keys are the field names and the values are
      # +Arrays+ of [latitude, longitude] pairs.
      #
      # Example:
      #
      # <tt>criteria.near(:field1 => [30, -44])</tt>
      #
      # Returns: <tt>self</tt>
      def near(attributes = {})
        update_selector(attributes, "$near")
      end

      # Adds a criterion to the +Criteria+ that specifies values that must
      # be matched in order to return results. This is similar to a SQL "WHERE"
      # clause. This is the actual selector that will be provided to MongoDB,
      # similar to the Javascript object that is used when performing a find()
      # in the MongoDB console.
      #
      # Options:
      #
      # selectior: A +Hash+ that must match the attributes of the +Document+.
      #
      # Example:
      #
      # <tt>criteria.where(:field1 => "value1", :field2 => 15)</tt>
      #
      # Returns: <tt>self</tt>
      def where(selector = nil)
        case selector
        when String
          @selector.update("$where" => selector)
        else
          @selector.update(selector ? selector.expand_complex_criteria : {})
        end
        self
      end
      
      def inclusions
        @inclusions ||= []
      end
      
      def includes(*relations)                
        relations.each do |name|
          inclusions.push(klass.reflect_on_association(name, true))
        end
        clone
      end
      
      def subclasses_includes(*subclasses_relations)
        subclasses_relations.each do |relation|
          if relation.is_a?(Hash)
            klass, relation_name = relation.first
            klass_instance = Object.module_eval("::#{klass}", __FILE__, __LINE__)
            inclusions.push(klass_instance.reflect_on_association(relation_name, true))
          end
        end
        clone
      end
      
      def load_ids(key)
        driver.find(selector, { :fields => { key => 1 }}).map { |doc| doc[key] }
      end
      
    end
  end
end
