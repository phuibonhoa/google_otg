$:.unshift(File.dirname(__FILE__))
require 'gchart_mod'
require 'uri'

module GoogleOtg

    DEFAULT_RANGE = 30 # 30 min

    def google_line_graph(hits, args = {})
    
        raise ArgumentError, "Invalid hits" unless hits && hits.length > 0
        
        size = args.has_key?(:size) ? args[:size] : '800x200'
        title = args.has_key?(:title) ? args[:title] : "Graph"
        title_color = args.has_key?(:title_color) ? args[:title_color] : '000000'
        title_size = args.has_key?(:title_size) ? args[:title_size] : '20'
        grid_lines = args.has_key?(:grid_lines) ? args[:grid_lines] : [25,50]
        legend = args.has_key?(:legend) ? args[:legend] : nil

        x_labels = []
        y_labels = [0]
        data = []
                
        if hits[0].is_a?(Array)
            shape_markers = [['o','0000ff',0,'-1.0',6],['o','FF6600',1,'-1.0',6]]
            line_colors = ['6699CC','FF9933']
            
            hits.map{|h|
                converted = hits_to_gchart_range(h, args)            
                data.push(converted[:points])
                x_labels = converted[:x_labels] if converted[:x_labels].length > x_labels.length
                y_labels = converted[:y_labels] if converted[:y_labels].max > y_labels.max
            }
            
        else
            shape_markers = ['o','0000ff',0,'-1.0',6]
            line_colors = '6699CC'            

            converted = hits_to_gchart_range(hits, args)            
            data.push(converted[:points])
            x_labels = converted[:x_labels]
            y_labels = converted[:y_labels]

        end
        
        axis_with_labels = 'x,y'
        axis_labels = [x_labels,y_labels]
        
        return Gchart.line(
            :size => size, 
            :title => title,
            :title_color => title_color,
            :title_size => title_size,
            :grid_lines => grid_lines,
            :shape_markers => shape_markers,
            :data => data,
            :axis_with_labels => axis_with_labels,
            :legend => legend,
            :axis_labels => axis_labels,
            :line_colors => line_colors)
                
    end
    
    def over_time_graph(hits, args = {})
        height = args.has_key?(:height) ? args[:height] : 125
        src = args.has_key?(:src) ? args[:src] : "http://www.google.com/analytics/static/flash/OverTimeGraph.swf"
        
        range = hits_to_otg_range(hits, args)
        vars = range_to_flashvars(range)
        
        html = <<-eos
<embed width="100%" height="#{height}"
wmode="opaque" salign="tl" scale="noScale" quality="high" bgcolor="#FFFFFF"
flashvars="input=#{vars}" 
pluginspage="http://www.macromedia.com/go/getflashplayer" type="application/x-shockwave-flash" 
src="#{src}"/>
eos

        return html

    end

    def google_pie(hits, label_fn, args = {})
        height = args.has_key?(:height) ? args[:height] : 125
        width = args.has_key?(:width) ? args[:width] : 125
        pie_values = extract_pct_values(hits, label_fn, args)
        vars = pie_to_flashvars(pie_values, args)
        src = args.has_key?(:src) ? args[:src] : "http://www.google.com/analytics/static/flash/pie.swf"
        
        html = <<-eos
<embed 
    width="#{width}" 
    height="#{height}" 
    salign="tl" 
    scale="noScale" 
    quality="high" 
    bgcolor="#FFFFFF" 
    flashvars="input=#{vars}&amp;locale=en-US" 
    pluginspage="http://www.macromedia.com/go/getflashplayer" 
    type="application/x-shockwave-flash" 
    src="#{src}"/>
eos
        return html
        
    end
    
    def pie_to_flashvars(args = {})

        labels = args[:labels]
        raw_values = args[:raw_values]
        percent_values = args[:percent_values]
            
        options = {
            :Pie => {
                :Id => "Pie",
                :Compare => false,
                :HasOtherSlice => false,
                :RawValues => raw_values,
                :Format => "DASHBOARD",
                :PercentValues => percent_values
            }
        }

        return URI::encode(options.to_json)

    end
    protected :pie_to_flashvars
    
    def extract_pct_values(hits, label_fn, args = {})

        limit = args.has_key?(:limit) ? args[:limit] : 0.0

        total = 0.0
        other = 0.0
        percent_values = []
        raw_values = []
        labels = []
        values = []
        hits.each{|hit|  
            total += hit.count.to_f
        }
        hits.each{|hit|
            ct = hit.count.to_f
            pct = (ct / total)
            
            if pct > limit 
                percent_values.push([pct, sprintf("%.2f%%", pct * 100)])
                raw_values.push([ct, ct])
                
                label = label_fn.call(hit)
                meta = args.has_key?(:meta) ? args[:meta].call(hit) : nil
                
                labels.push(label)
                values.push({:label => label, :meta => meta, :percent_value => [pct, sprintf("%.2f%%", pct * 100)], :raw_value => ct})
            else
                other += ct
            end
        }
        if other > 0.0
            pct = other / total
            percent_values.push([pct, sprintf("%.2f%%", pct * 100)])
            raw_values.push([other, other])
            labels.push("Other")
            values.push({:label => "Other", :percent_value => [pct, sprintf("%.2f%%", pct * 100)], :raw_value => other})
        end

        return {:labels => labels, :raw_values => raw_values, :percent_values => percent_values, :values => values}

    end
    protected :extract_pct_values
    
    def flto10(val)
        return ((val / 10) * 10).to_i
    end
    protected :flto10
    
    def hits_to_otg_range(hits, args = {})
        return hits_to_range(hits, lambda {|count, date_key, date_value| 
            {:Value => [count, count], :Label => [date_key, date_value]}
        }, lambda{|mid, top| 
            [[mid,mid],[top,top]]
        }, lambda{|hit, hit_date_key, hit_date_value|
            [hit_date_key, hit_date_value]
        },args)
    end
    
    def hits_to_gchart_range(hits, args = {})
        return hits_to_range(hits, lambda {|count, date_key, date_value|
            count
        }, lambda {|mid, top|
            [0,top/2,top]
        },lambda{|hit, hit_date_key, hit_date_value|
            hit_date_value
        }, args)
    end
    
    def hits_to_range(hits, points_fn, y_label_fn, x_label_fn, args = {})

        return nil unless hits
        
        hits.map{|h|
            if !h.respond_to?("created_at") || !h.respond_to?("count")
                raise ArgumentError, "Invalid object type. All objects must respond to 'count' and 'created_at'"
            end
        }
      
        tz = args.has_key?(:time_zone) ? args[:time_zone] : ActiveSupport::TimeZone['UTC']
        label = args.has_key?(:label) ? args[:label] : "Value"
        time_fn = args.has_key?(:time_fn) ? args[:time_fn] : lambda {|h| 
            return tz.local(h.created_at.year, h.created_at.month, h.created_at.day, h.created_at.hour, h.created_at.min, h.created_at.sec) # create zoned time
        }
        range = args.has_key?(:range) ? args[:range] : DEFAULT_RANGE
        x_label_format = args.has_key?(:x_label_format) ? args[:x_label_format] : "%A %I:%M%p"
      
        max_y = 0
        hits_dict = {}
        hits.each { |h|
            hits_dict[time_fn.call(h)] = h
        }

        total = 0
        
        points = []
        point_dates = []

        now_days = tz.now # use this get the right year, month and day
        now_minutes = tz.at((now_days.to_i/(60*range))*(60*range)).gmtime
        now_floored = tz.local(now_days.year, now_days.month, now_days.day, 
            now_minutes.hour, now_minutes.min, now_minutes.sec)

        current = hits.length > 0 ? time_fn.call(hits[0]) : now_floored

        while (current < now_floored + range.minutes && range > 0) do
            if hits_dict[current]
                count = hits_dict[current].count.to_i
                max_y = count if count > max_y

                date = time_fn.call(hits_dict[current])
                date_key = date.to_i
                date_value = date.strftime(x_label_format)
                
                points.push(points_fn.call(count, date_key, date_value))
                total += count
            else
            
                date = current
                date_key = date.to_i
                date_value = date.strftime(x_label_format)
                
                points.push(points_fn.call(0, date_key, date_value))
            end
            # Save the date for the x labels later
            point_dates.push({:key => date_key, :value => date_value})
            current = current + range.minutes
            break if points.length > 100 
        end

        ## Setup Y axis labels ##
        max_y = args.has_key?(:max_y) ? (args[:max_y] > max_y ? args[:max_y] : max_y) : max_y

        top_y = self.flto10(max_y) + 10
        mid_y = self.flto10(top_y / 2)        
        y_labels = y_label_fn.call(mid_y, top_y)
        ## end y axis labels ##

        ## Setup X axis labels
        x_labels = []
        max_x_label_count = args.has_key?(:max_x_label_count) ? args[:max_x_label_count] : points.length

        if points.length > 0    
            step = [points.length / max_x_label_count, 1].max
            idx = 0
            
            while idx < points.length
                point = points[idx]
                date = point_dates[idx]
                x_labels.push(x_label_fn.call(point, date[:key], date[:value]))
                idx += step
            end
        end
        
        ## End x axis labels ##
        
        return {:x_labels => x_labels, :y_labels => y_labels, :label => label, :points => points, :total => total}    
        
    end
    protected :hits_to_range
    
    def range_to_flashvars(args = {})
        x_labels = args[:x_labels]
        y_labels = args[:y_labels]
        label = args[:label]
        points = args[:points]
        
        raise ArgumentError unless x_labels
        raise ArgumentError unless y_labels
        raise ArgumentError unless label
        raise ArgumentError unless points
        
            # this is the structure necessary to support the Google Analytics OTG

            options = {:Graph => {
            :Id => "Graph",
            :ShowHover => true,
            :Format => "NORMAL",
            :XAxisTitle => "Day",
            :Compare => false, 
            :XAxisLabels => x_labels,
            :HoverType => "primary_compare",
            :SelectedSeries => ["primary", "compare"],
            :Series => [
                {
                    :SelectionStartIndex => 0,
                    :SelectionEndIndex => points.length,
                    :Style => 
                    {
                        :PointShape => "CIRCLE",
                        :PointRadius => 9,
                        :FillColor => 30668,
                        :FillAlpha => 10,
                        :LineThickness => 4,
                        :ActiveColor => 30668,
                        :InactiveColor => 11654895
                    },
                    :Label => label,
                    :Id => "primary",
                    :YLabels => y_labels,
                    :ValueCategory => "visits",
                    :Points => points
                        }]        
                } # end graph
            } # end options

        return URI::encode(options.to_json)
    end
    protected :range_to_flashvars

end