# Modified from project 3
# to accept extra parameters

#struct def
City = Struct.new(:id, :x, :y, :next)

#constant
ALargeNumber = (2**100)

#globals
$filename = ""
$outputcount = 0    #output filename counter
$current = []
$last_inserted_node = 0
$conv = ARGV[1]
$whatsleft = ARGV[2]

#Checks arg count and if file exists
def set_input_filename()
    if ARGV.length != 3
        puts "usage: ruby greedy.rb [filename] [city-array] [points]"
        exit
    elsif !FileTest.file?(ARGV[0])
        puts "file does not exist"
        exit
    else
        $filename = ARGV[0]
        #make folder for file outputs
        Dir.mkdir "z_#{$filename[0..-5].to_s}" unless File.exist? "z_#{$filename[0..-5].to_s}"
    end
end

#creates an array of cities from text file
def get_cities()
    array = []                                          #array init
    flag = false                                        #flag for node_coord_section loop
    File.open($filename, "r").each do |line|
        temp = line
        if temp.include? "NODE_COORD_SECTION"           #skip through textfile until this line is reached
            flag = true
            next
        end
        if flag == true                                 #start grabbing coordinate info
            temp = temp.split()
            node = City.new(temp[0], temp[1], temp[2], nil)
            temp[0] == "1" ? (node.next = nil) : (node.next = array[-1])
            array << node
        end
    end
    if array.length > 0                                 #if no coords in file, or random txt file is used, exit program
        puts "Coordinates Found. \n"
        return array
    else
        puts "No coordinates found"
        exit
    end
end

#calculates distance from 2 cities
def distance(a, b)
    return Math.sqrt((a.x.to_f - b.x.to_f)**2 + (a.y.to_f - b.y.to_f)**2)
end

def print_city_ids(array)
    print "|-"
    array.each { |city| print city.id + "-" }
    puts "|"
end

def minimum_distance(p, a, b)
    length = (a.x.to_f - b.x.to_f)**2 + (a.y.to_f - b.y.to_f)**2
    
    if length == 0
        return (distance(p, a))
    else
        #projection
        t = ((((p.x.to_f - a.x.to_f) * (b.x.to_f - a.x.to_f)) + ((p.y.to_f - a.y.to_f) * (b.y.to_f - a.y.to_f))) / length).to_f
        #if point is too far right or left of line, just compare from line endpoints
        if t < 0
            return (distance(p, a))
        elsif t > 1
            return (distance(p, b))
        else #return closest point on line distance
			temp = City.new(-1, (a.x.to_f + t * (b.x.to_f - a.x.to_f)).to_f, (a.y.to_f + t * (b.y.to_f - a.y.to_f)).to_f, nil)
            return distance(p, temp)
        end
    end
end

def smart_insert(city_array, current)
    shortest = ALargeNumber
    i = nil     #insertion index
    ci = nil    #point (city)
    pi = nil    #point index
    current.each.with_index { |line, index| #for every line in the graph
        city_array.each.with_index { |point, point_index| #compare every not-added point to lines in graph
            x = minimum_distance(point, current[index], current[(index + 1) % current.length])
            if (x < shortest)    #normal case
                shortest = x.dup

                i = ((index+1) % current.length)
                ci = point;
                pi = point_index;
            elsif (x == shortest) #two adjacent lines both do distance compare from the same coordinate
                if (index.to_s == (current.length - 1).to_s) || (index == 0) #weird edge case involving first/last element in the current array
                    if (distance(current[i-1], point) + distance(point, current[i]) + distance(current[i-2], current[(i-1)])) > (distance(current[index], point) + distance(point, current[((index + 1) % current.length)]) + distance(current[((index + 1) % current.length)], current[((index + 2) % current.length)]))
                        i = ((index+1) % current.length)
                        ci = point;
                        pi = point_index;
                    end
                #two lines compare to same point, check distance of inserting one or the other
                elsif (distance(current[i-1], point) + distance(point, current[i]) + distance(current[i], current[((i+1) % current.length)]) > (distance(current[index], point) + (distance(point, current[((index + 1) % current.length)] ) + distance(current[index-1], current[index]))))
                    i = ((index+1) % current.length)
                    ci = point;
                    pi = point_index;
                end
            end
        }
    }
    return [ci, i, pi]
end

def get_total_distance(array)
    result = 0
    array.each.with_index { |city, index|
        result += distance(city, array[(index+1) % array.length])
    }
    return result
end

#make html svg graphics of current state
def output_file(array)
    outname = $outputcount.to_s.rjust(4, "0000") + ".html"
    out = File.open("z_" + $filename[0..-5] + "/" + outname, "w")
    out.puts "<!DOCTYPE HTML>"
    out.puts "<head>"
    out.puts "<style>"
    out.puts "p {\n\tmargin: 4px;\n} body {\n\tbackground-color: #eee;\n}\nsvg {\n\tborder: 1px solid black;\n\twidth: 550px;\n\theight: 550px;\n}\nsvg g circle {\n\tz-index: 10;\n}\nsvg g text {\n\tfont-size: 13px;\n}\nsvg g line {\n\tstroke:rgb(0,0,0);\n\tstroke-width:2; \n\tz-index: -1;\n}\n.b{\n\tstroke: rgb(255,255,255);\n\tstroke-width: 1;\n} "
    out.puts "</style>"
    out.puts "</head>"
    out.puts "<body>"
    out.puts "<svg>"
    
    li = 50

    out.puts "<g>"
    array.each.with_index { |city, index| 
        top = 103
        prev_x = array[index-1].x.to_f * 5
        prev_y = (top - array[index-1].y.to_f) * 5
        x = city.x.to_f
        x *= 5
        y = top - city.y.to_f
        y *= 5
        out.puts("<circle cx=\"#{x}\" cy=\"#{y}\" r=\"6\" stroke                                                                                                                                    =\"black\" stroke-width=\"1\" fill=\"black\"> <title>id: #{city.id} \nx: #{city.x} \ny: #{city.y}</title> </circle>")
        out.puts("<text x=\"#{x+5}\" y=\"#{y-5}\">#{city.id}</text>")
        out.puts("<line x1=\"#{x}\" y1=\"#{y}\" x2=\"#{prev_x}\" y2=\"#{prev_y}\"> <title>#{array[index-1].id} to #{city.id}</title> </line>")
    }

    out.puts "</g>"
    out.puts "</svg>"
    out.puts "<div style=\"width: 300px; height: auto; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word; \">"
    out.puts "<p style = \"font-size: 12px; color: #666;\">hover over nodes/lines for info</p><p>"
    out.print "Frame #: "
    out.puts (outname[0..-6].to_i)/10 + 1
    out.puts "</p>"
    td = get_total_distance(array)
    out.puts "<p>inserted: #{$last_inserted_node}<br>total distance: #{td.to_s[0..12]}</p>"
    out.print "<p>| -"
    array.each { |city| out.print city.id + " - " }
    out.puts "|"
    out.puts "</p>"
    out.puts "</div>"
    out.puts "</body>"
    $outputcount += 10
end

# --- begin main ---

elapsed_time = Time.now

set_input_filename()
city_array = get_cities()

conv = $conv.split("-")
conv.delete("|")
xresult = []

conv.each { |id|
    xresult.insert(-1, city_array[(id.to_i)-1])
}

conv = $whatsleft.split("-")
conv.delete("|")
yresult = []

conv.each { |id|
    yresult.insert(-1, city_array[(id.to_i)-1])
}

city_array = yresult.dup
$current = xresult.dup

until city_array.empty?
    #if two points in graph, compare points to lines
    if $current.length >= 2
        result = smart_insert(city_array, $current)
        $current.insert(result[1].to_i, result[0])
        city_array.delete_at(result[2])
        $last_inserted_node = result[0].id
        print "#{result[0].id}, " 
    #if no points, insert one randomly
    elsif $current.length == 0
        node = city_array.delete_at(rand(city_array.length))
        $current.push(node)
        $last_inserted_node = node.id
        print "inserted - #{node.id}, " 
    #if one point, insert closest point to point
    else $current.length == 1
        node = nil
        node_index = nil    
        smallest = ALargeNumber
        city_array.each.with_index { |city, index|
            x = distance(city, $current[0])
            if (x < smallest)
                smallest = x
                node = city
                node_index = index
            end
        }
        $current.push(node)
        city_array.delete_at(node_index)
        $last_inserted_node = node.id
        print "#{node.id}, " 
    end
    # print_city_ids($current)
    output_file($current)
end

puts
puts "final distance: #{get_total_distance($current)}"

elapsed_time = Time.now - elapsed_time  #timer for report graph
puts "\nCompleted in " + elapsed_time.to_s + " seconds."
