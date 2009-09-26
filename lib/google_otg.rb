require 'uri'

module GoogleOtg

    DEFAULT_RANGE = 30 # 30 min

    def over_time_graph(hits, args = {})
        height = args.has_key?(:height) ? args[:height] : 125
        src = args.has_key?(:src) ? args[:src] : "http://www.google.com/analytics/static/flash/OverTimeGraph.swf"
        
        range = hits_to_range(hits, args)
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
    
    def hits_to_range(hits, args = {})

        return nil unless hits
        
        hits.map{|h|
            if !h.respond_to?("created_at") || !h.respond_to?("count")
                raise ArgumentError, "Invalid object type. All objects must respond to 'count' and 'created_at'"
            end
        }
      
        tz = args.has_key?(:time_zone) ? args[:time_zone] : ActiveSupport::TimeZone['UTC']
        Time.zone = tz
        label = args.has_key?(:label) ? args[:label] : "Value"
        time_fn = args.has_key?(:time_fn) ? args[:time_fn] : lambda {|h| h.created_at }
        range = args.has_key?(:range) ? args[:range] : DEFAULT_RANGE
        x_label_format = args.has_key?(:x_label_format) ? args[:x_label_format] : "%A %I:%M%p"
      
        max_y = 0
        hits_dict = {}
        hits.each { |h|
            hits_dict[time_fn.call(h)] = h
        }

        total = 0
        
        points = []
        now_floored = Time.at((Time.now.to_i/(60*range))*(60*range))
        current = hits.length > 0 ? time_fn.call(hits[0]) : now_floored

        while (current <= now_floored && range > 0) do
            if hits_dict[current]
                count = hits_dict[current].count.to_i
                max_y = count if count > max_y

                date = time_fn.call(hits_dict[current])
                date_key = date.to_i
                date_value = date.strftime(x_label_format)
                
                points.push({:Value => [count, count], :Label => [date_key, date_value]})
                total += count
            else
            
                date = current
                date_key = date.to_i
                date_value = date.strftime(x_label_format)
                
                points.push({:Value => [0, 0], :Label => [date_key, date_value]})
            end
            current = current + range.minutes
            if points.length > 100 
                break
            end
        end

        max_y = args.has_key?(:max_y) ? (args[:max_y] > max_y ? args[:max_y] : max_y) : max_y

        mid_y = self.flto10(max_y / 2)
        top_y = self.flto10(max_y)
        if (top_y == 0)
            mid_y = max_y / 2
            top_y = max_y
        end
        
        y_labels = [ [mid_y, mid_y], [top_y, top_y] ]

        x_labels = []

        if points.length > 0    
            for i in 0..3
                hit = points[i * (points.length / 4)]
                
                date_key = hit[:Label][0]
                date_value = hit[:Label][1]
                x_labels.push([date_key, date_value])
            end
        end
        return {:x_labels => x_labels, :y_labels => y_labels, :label => label, :points => points, :total => total}    
        
    end
    
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