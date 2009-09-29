require 'gchart'

class Gchart
    attr_accessor :grid_lines, :shape_markers
    
    def set_shape_markers
        shape_markers_values = case @shape_markers
        when String
            @shape_markers
        when Array
            if @shape_markers[0].is_a?(Array)
                @shape_markers.map{|sm|sm.join(",")}.join("|")
            else
                @shape_markers.join("|")
            end
        when Hash
            marker_type = @shape_markers[:marker_type]
            color = @shape_markers[:color]
            data_set_index = @shape_markers[:data_set_index]
            data_point = @shape_markers[:data_point]
            size = @shape_markers[:size]
            priority = @shape_markers[:priority]
            [marker_type,color,data_set_index,data_point,size,priority].join(",")
        else
            @shape_makers.to_s
        end
        "chm=#{shape_markers_values}"
    end
    
    def set_grid_lines
        grid_lines_values = case @grid_lines
        when String
            @grid_lines
        when Array
            @grid_lines.join(",")
        when Hash
            x_step = @grid_lines[:x_step]
            y_step = @grid_lines[:y_step]
            line_length = @grid_lines[:line_length]
            blank_length = @grid_lines[:blank_length]
            x_offset = @grid_lines[:x_offset]
            y_offset = @grid_lines[:y_offset]
            [x_step,y_step,line_length,blank_length,x_offset,y_offset].join(",")
        else
            @grid_lines.to_s
        end
        "chg=#{grid_lines_values}"
    end

  def query_builder(options="")
    dataset 
    query_params = instance_variables.map do |var|
      case var
      when '@data'
        set_data unless @data == []  
      # Set the graph size  
      when '@width'
        set_size unless @width.nil? || @height.nil?
      when '@type'
        set_type
      when '@title'
        set_title unless @title.nil?
      when '@legend'
        set_legend unless @legend.nil?
      when '@bg_color'
        set_colors
      when '@chart_color'
        set_colors if @bg_color.nil?
      when '@bar_colors'
        set_bar_colors
      when '@bar_width_and_spacing'
        set_bar_width_and_spacing
      when '@axis_with_labels'
        set_axis_with_labels
      when '@axis_range'
        set_axis_range if dataset
      when '@axis_labels'
        set_axis_labels
      when '@range_markers'
        set_range_markers
      when '@geographical_area'
        set_geographical_area
      when '@country_codes'
        set_country_codes
      when '@grid_lines'
        set_grid_lines
      when '@shape_markers'
        set_shape_markers
      when '@custom'
        @custom
      end
    end.compact
    
    # Use ampersand as default delimiter
    unless options == :html
      delimiter = '&'
    # Escape ampersand for html image tags
    else
      delimiter = '&amp;'
    end
    
    jstize(@@url + query_params.join(delimiter))
  end

end