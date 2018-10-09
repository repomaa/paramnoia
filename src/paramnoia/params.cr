require "json"
require "http"

require "./error"

module Paramnoia
  annotation Settings
  end

  module Params
    annotation Field
    end

    include JSON::Serializable

    macro included
      def self.from_urlencoded(string)
        new(HTTP::Params.parse(string))
      end
    end

    macro string_value_from_params(params, name, nilable, has_default_value, default_value)
      %values = string_values_from_params({{params}}, {{name}}, {{nilable}}, {{has_default_value}})
      {% if nilable || has_default_value %}
        %values.empty? ? {{has_default_value ? default_value : nil}} : %values.last
      {% else %}
        %values.last
      {% end %}
    end

    macro string_values_from_params(params, name, nilable, has_default_value)
      {% if nilable || has_default_value %}
        {{params}}.fetch_all({{name}})
      {% else %}
        {{params}}.fetch_all({{name}}).tap do |values|
          raise KeyError.new(%|Missing hash key: "#{{{name}}}"|) if values.empty?
        end
      {% end %}
    end

    def initialize(http_params : HTTP::Params, path = %w[])
      {% begin %}
        {% settings = @type.annotation(::Paramnoia::Settings) || { strict: false } %}

        {% for ivar in @type.instance_vars %}
          {% non_nil_type = ivar.type.union? ? ivar.type.union_types.reject { |type| type == ::Nil }.first : ivar.type %}
          {% nilable = ivar.type.nilable? %}
          {% has_default = ivar.has_default_value? %}
          {% default = ivar.default_value %}
          {% ann = ivar.annotation(::Paramnoia::Params::Field) %}
          {% converter = ann && ann[:converter] %}
          {% key = (ann && ann[:key] || ivar.name.stringify) %}

          %param_name = (path + [{{key}}]).reduce { |result, fragment| "#{result}[#{fragment}]" }
          {% if converter %}
            %values = string_values_from_params(http_params, %param_name, {{nilable}}, {{has_default}})
            {% if nilable || has_default %}
              if %values.empty?
                @{{ivar.name}} = {{has_default ? default : nil}}
              else
            {% end %}
              @{{ivar.name}} = {{converter}}.from_params(%values)
            {% if nilable || has_default %}
              end
            {% end %}

          {% elsif non_nil_type <= Array %}
            %values = string_values_from_params(http_params, "#{%param_name}[]", {{nilable}}, {{has_default}})
            {% if nilable || has_default %}
              if %values.empty?
                @{{ivar.name}} = {{has_default ? default : nil}}
              else
            {% end %}

            @{{ivar.name}} = %values.map do |item|
              {% item_type = non_nil_type.type_vars.first %}
              {% if item_type <= String %}
                item
              {% elsif item_type == Bool %}
                !\%w[0 false no].includes?(item)
              {% elsif item_type <= Enum %}
                {{item_type}}.parse(item)
              {% else %}
                {{item_type}}.new(item)
              {% end %}
            end

            {% if nilable || has_default %}
              end
            {% end %}

            {% if settings[:strict] %}
              handled_param_names << "#{%param_name}[]"
            {% end %}

          {% elsif non_nil_type <= Tuple %}
            %values = http_params.fetch_all("#{%param_name}[]")
            @{{ivar.name}} = {
              {% for item_type, index in non_nil_type.type_vars %}
                {% if item_type <= String %}
                  item
                {% elsif item_type == Bool %}
                  !\%w[0 false no].includes?(item)
                {% elsif item_type <= Enum %}
                  {{item_type}}.parse(item)
                {% else %}
                  {{item_type}}.new(item)
                {% end %}
                ,
              {% end %}
            }

            {% if settings[:strict] %}
              handled_param_names << "#{%param_name}[]"
            {% end %}

          {% elsif non_nil_type <= ::Paramnoia::Params %}
            %nested_params = HTTP::Params.new
            http_params.each do |key, value|
              if key.starts_with?("#{%param_name}[")
                %nested_params.add(key, value)
                {% if settings[:strict] %}
                  handled_param_names << key
                {% end %}
              end
            end

            if %nested_params.any?
              @{{ivar.name}} = {{non_nil_type}}.new(%nested_params, path + [{{ivar.name.stringify}}])
            else
              {% if nilable %}
                @{{ivar.name}} = nil
              {% else %}
                raise KeyError.new(%|Missing nested hash keys: "#{%param_name}"|)
              {% end %}
            end

          {% elsif non_nil_type == String %}
            @{{ivar.name}} = string_value_from_params(http_params, %param_name, {{nilable}}, {{has_default}}, {{default}})
            {% if settings[:strict] %}
              handled_param_names << %param_name
            {% end %}

          {% elsif non_nil_type == Bool %}
            %value = string_value_from_params(http_params, %param_name, {{nilable}}, {{has_default}}, {{default}})
            {% if nilable %}
              if %value.nil?
                @{{ivar.name}} = nil
              else
            {% end %}
            @{{ivar.name}} = !\%w[0 false no].includes?(%value.downcase)
            {% if nilable %}
              end
            {% end %}
            {% if settings[:strict] %}
              handled_param_names << %param_name
            {% end %}

          {% elsif non_nil_type <= ::Enum %}
            %value = string_value_from_params(http_params, %param_name, {{nilable}}, {{has_default}}, {{default}})
            @{{ivar.name}} = {{non_nil_type}}.parse(%value)
            {% if settings[:strict] %}
              handled_param_names << %param_name
            {% end %}

          {% else %}
            %value = string_value_from_params(http_params, %param_name, {{nilable}}, {{has_default}}, {{default}})
            {% if nilable %}
              if %value.nil?
                @{{ivar.name}} = nil
              else
            {% end %}
              @{{ivar.name}} = {{non_nil_type}}.new(%value)
            {% if nilable %}
              end
            {% end %}
            {% if settings[:strict] %}
              handled_param_names << %param_name
            {% end %}
          {% end %}
        {% end %}

        {% if settings[:strict] %}
          http_params.each do |key, _|
            raise %|Unknown param: "#{key}"| unless handled_param_names.includes?(key)
          end
        {% end %}
      {% end %}
    end
  end
end
