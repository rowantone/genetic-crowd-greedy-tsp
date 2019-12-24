require 'set'

#struct def
City = Struct.new(:id, :x, :y)
Path = Struct.new(:array, :dist)

ALargeNumber = (2**100)

#globals
$filename = ""
$outputcount = 0    #output filename counter
$child1 = []
$child2 = []
$td = 0
$gen_count = ARGV[1].to_i
$pop_count = ARGV[2].to_i
$accept_ratio = ARGV[3].to_f

#hash table to make fitness function a little faster
$pathparts = Hash.new  

#Checks arg count and if file exists
def set_input_filename()
    if ARGV.length != 4
        puts "usage: ruby source.rb [filename] [gen-count] [pop-count] [woc ratio (0-1)]"
        exit
    elsif !FileTest.file?(ARGV[0])
        puts "file does not exist"
        exit
    else
        $filename = ARGV[0]
        #make folder for file outputs
        Dir.mkdir $filename[0..-5].to_s unless File.exist? $filename[0..-5].to_s
        $report = File.open($filename[0..-5] + "/report.txt", "w")
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
            node = City.new(temp[0], temp[1].to_f, temp[2].to_f)
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
    key = "#{a[0]}, #{b[0]}"
    if ($pathparts[key]) != nil
        return $pathparts[key]
    else
        x = Math.sqrt((a.x.to_f - b.x.to_f)**2 + (a.y.to_f - b.y.to_f)**2)
        $pathparts[key] = x
        return x
    end
end

#elegant city-id print
def print_city_ids(array)
    print "|-"
    array.each { |city| 
        if city != nil
            print city.id + "-" 
        else
            print "nil-"
        end
    }
    puts "|"
end

#printed city-ids to string
def return_city_ids(array)
    result = ""
    result.concat("|-")
    array.each { |city| 
        if city != nil
            result.concat(city.id + "-")
        else
            result.concat("nil-")
        end
    }
    result.concat("|")
    return result
end

#return total distance of city-array
def get_total_distance(array)
    result = 0
    array_length = array.length
    array.each.with_index { |city, index|
        result += distance(city, array[(index+1) % array_length])
    }
    return result
end

#scramble city-array
def scramble_array(array)
    scrambled = []
    until array.empty? == true
        scrambled.insert(-1, array.delete_at(rand array.length))
    end
    return scrambled
end

#no predetermined size ox1
def ox1_mod(path1, path2)
    path_size = path1.length
    index1 = rand (path1.length - 1)
    index2 = rand (index1...path1.length)
    size = index2-index1
    final_array = []
    
    segment = []
    for a in 0..(size-1) do
        segment.insert(-1, path1[index1+a])
    end

    child = []
    cindex = index2.dup
    child.insert(index1, *segment)     #splat
    for a in index2..path_size-1 do
        grab = path2[a]
        if !segment.include? grab
            child.insert(cindex, grab.dup)
            cindex = (cindex + 1) % path_size
        end
    end
    for a in 0..index2
        grab = path2[a]
        if !segment.include? grab
            child[cindex] = grab.dup
            cindex = (cindex + 1) % path_size
        end
        if cindex == index1
            break
        end
    end
    # $child1 = child.dup
    final_array[0] = child.dup

    #-------------------------------------------
    segment.clear
    for a in 0..(size-1) do
        segment.insert(-1, path2[index1+a])
    end

    child.clear
    cindex = index2.dup
    child.insert(index1, *segment)     #splat
    for a in index2..path_size-1 do
        grab = path1[a]
        if !segment.include? grab
            child.insert(cindex, grab.dup)
            cindex = (cindex + 1) % path_size
        end
    end
    for a in 0..index2
        grab = path1[a]
        if !segment.include? grab
            child[cindex] = grab.dup
            cindex = (cindex + 1) % path_size
        end
        if cindex == index1
            break
        end
    end

    # $child2 = child.dup

    final_array[1] = child.dup

    return final_array
end

#returns index of random weighted choice
def weighted_rand(array)
    final = []
    xflag = false
    zflag = false

    y = array.map { |a| (1/a.dist).to_f; }
    ysum = y.sum.to_f
    x = rand * ysum
    z = rand * ysum

    cum = 0
    y.each.with_index { |path, i|
        if (zflag == true && xflag == true)        
            break;
        elsif (((cum + (path)) > x) && xflag == false)
            final.insert(-1, i)
            xflag = true
        elsif (((cum + (path)) > z) && zflag == false)
            final.insert(-1, i)
            zflag = true
        else
            cum += path
        end
    }
    (final[1] == nil) ? (final[1] = y.length - 1) : ()
    return final
end

#wisdom of crowds
def weighted_matrix(array)
    max_val = $pop_count/10
    weary = []
    wsum = 0

    #removing elements below ratio
    for item in array do
        if ($accept_ratio * max_val) >= item
            weary.insert(-1, 0)
        else
            weary.insert(-1, item)
            wsum += item
        end
    end
    
    if wsum == 0
        return -1
    end

    weary = weary.map { |w|
        w/wsum
    }

    wsum = weary.sum
    x = rand * wsum
    cum = 0

    #weighted selection of connections (w.o.c)
    weary.each.with_index { |w, index|
        if w == 0
            next
        elsif ((cum + w) > x)
            return index
        else
            cum += w
        end
    }

    # return array.index(array.max)

    return -1
end

#roll to see if random mutation occurs - 2% chance
def rng_mut()
    x = rand()
    if x >= 0.50 && x <= 0.52
        return true
    else
        return false
    end
end

#mutates city array - rsm operator
def mutate_rsm(array)
    i = rand(array.length-1)
    j = rand(i...(array.length-1))
    b = array.slice(i, j)
    array -= b
    b.reverse!
    array.insert(i, *b)
    return array
end

#mutates city array - for dekinker
def mutate_rsm_alt(array, i, j)
    # puts "mutating: #{i} & #{j} || "
    b = array.slice(i, j)
    array -= b
    b.reverse!
    array.insert(i, *b)
    return array
end

#agreement matrix init.
def make_matrix(size)
    x = []
    for a in 0...size
        x.insert(-1, 0)
    end
    y = []
    for b in 0...size
        y.insert(-1, x.dup)
    end
    return y
end

#terminal-print agreement matrix
def print_matrix(matrix)
    i = 1
    print ".....  "
    matrix.length.times do
        print "#{i.to_s.rjust(3,"0")}  "
        i += 1
    end
    puts
    i = 1
    for col in matrix
        print "#{i.to_s.rjust(3,"0")} | - "
        for row in col
            (row == $pop_count/10) ? (print "\e[1;31m██\e[0m" + " - ") : (print row.to_s.rjust(2,"0") + " - ")     #element
        end
        print "|"
        puts
        i += 1 
    end
end

#makes html file of city array
def output_file(array)
    a = array.array
    outname = ($outputcount*10).to_s.rjust(4, "0000") + ".html"
    out = File.open($filename[0..-5] + "/" + outname, "w")
    out.puts "<!DOCTYPE HTML>"
    out.puts "<head>"
    out.puts "<style>"
    out.puts "p {\n\tmargin: 4px;\n} body {\n\tbackground-color: #eee;\n}\nsvg {\n\tborder: 1px solid black;\n\twidth: 550px;\n\theight: 550px;\n}\nsvg g circle {\n\tz-index: 10;\n}\nsvg g text {\n\tfont-size: 10px;\n\tcolor:#555;\n}\nsvg g line {\n\tstroke:rgb(0,0,0);\n\tstroke-width:2; \n\tz-index: -1;\n}\n.b{\n\tstroke: rgb(255,255,255);\n\tstroke-width: 1;\n} "
    out.puts "</style>"
    out.puts "</head>"
    out.puts "<body>"
    out.puts "<svg>"
    
    li = 50

    out.puts "<g>"
    a.each.with_index { |city, index| 
        top = 103
        prev_x = a[index-1].x.to_f * 5
        prev_y = (top - a[index-1].y.to_f) * 5
        x = city.x.to_f
        x *= 5
        y = top - city.y.to_f
        y *= 5
        out.puts("<circle cx=\"#{x}\" cy=\"#{y}\" r=\"6\" stroke=\"black\" stroke-width=\"1\" fill=\"black\"> <title>id: #{city.id} \nx: #{city.x} \ny: #{city.y}</title></circle>")
        out.puts("<text x=\"#{x+5}\" y=\"#{y-5}\">#{city.id}</text>")
        out.puts("<line x1=\"#{x}\" y1=\"#{y}\" x2=\"#{prev_x}\" y2=\"#{prev_y}\"> <title>#{a[index-1].id} to #{city.id}</title> </line>")
    }

    out.puts "</g>"
    out.puts "</svg>"
    out.puts "<div style=\"width: 300px; height: auto; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word; \">"
    out.puts "<p style = \"font-size: 12px; color: #666;\">hover over nodes/lines for info</p><p>"
    out.print "Generation #: "
    out.puts outname[0..-6].to_i
    out.puts "/#{$gen_count}"
    out.puts "</p>"
    $td = array.dist
    out.puts "<p>total distance: #{$td.to_s[0..12]}</p>"
    out.puts "<p>"
    out.print "| -"
    a.each { |city| out.print city.id + " - " }
    out.puts "|"
    out.puts "</p>"
    out.puts "</div>"
    out.puts "</body>"
    $outputcount += 1
    $report.puts "#{$td}"
end

#alternate output for woc
def output_file_woc(input, ref)
    count = 0
    print_array = []

    #turning chains into ids
    for array in input do
        print_array[count] = []
        for x in array do
            print_array[count].insert(-1, ref[x].dup)
        end
        count += 1
    end

    count = 0

    for array in print_array do
        a = array
        outname = ($outputcount*10).to_s.rjust(4, "0000") + ".html"
        out = File.open($filename[0..-5] + "/" + outname, "w")
        out.puts "<!DOCTYPE HTML>"
        out.puts "<head>"
        out.puts "<style>"
        out.puts "p {\n\tmargin: 4px;\n} body {\n\tbackground-color: #eee;\n}\nsvg {\n\tborder: 1px solid black;\n\twidth: 550px;\n\theight: 550px;\n}\nsvg g circle {\n\tz-index: 10;\n}\nsvg g text {\n\tfont-size: 10px;\n\tcolor:#555;\n}\nsvg g line {\n\tstroke:rgb(0,0,0);\n\tstroke-width:2; \n\tz-index: -1;\n}\n.b{\n\tstroke: rgb(255,255,255);\n\tstroke-width: 1;\n} "
        out.puts "</style>"
        out.puts "</head>"
        out.puts "<body>"
        out.puts "<svg>"
        
        li = 50

        out.puts "<g>"

        ref.each.with_index { |city, index|
            top = 103
            x = city.x.to_f
            x *= 5
            y = top - city.y.to_f
            y *= 5
            out.puts("<circle cx=\"#{x}\" cy=\"#{y}\" r=\"6\" stroke =\"black\" stroke-width=\"1\" fill=\"black\"> <title>id: #{city.id} \nx: #{city.x} \ny: #{city.y}</title> </circle>")
        }

        a.each.with_index { |city, index|
            if index == 0
                next
            end
            top = 103
            prev_x = a[index-1].x.to_f * 5
            prev_y = (top - a[index-1].y.to_f) * 5
            x = city.x.to_f
            x *= 5
            y = top - city.y.to_f
            y *= 5
            out.puts("<text x=\"#{x+5}\" y=\"#{y-5}\">#{city.id}</text>")
            out.puts("<line x1=\"#{x}\" y1=\"#{y}\" x2=\"#{prev_x}\" y2=\"#{prev_y}\"> <title>#{a[index-1].id} to #{city.id}</title> </line>")
        }

        out.puts "</g>"
        out.puts "</svg>"
        out.puts "<div style=\"width: 300px; height: auto; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word; \">"
        out.puts "<p style = \"font-size: 12px; color: #666;\">hover over nodes/lines for info</p><p>"
        out.puts "WOC CHAIN ##{count+1}"
        out.puts "</p>"
        out.puts "<p>total distance: #{$td.to_s[0..12]}</p>"
        out.puts "<p>"
        out.print "| -"
        a.each { |city| out.print city.id + " - " }
        out.puts "|"
        out.puts "</p>"
        out.puts "</div>"
        out.puts "</body>"
        $outputcount += 1
        count +=1
    end

    # for array in print_array do
        a = array
        outname = ($outputcount*10).to_s.rjust(4, "0000") + ".html"
        out = File.open($filename[0..-5] + "/" + outname, "w")
        out.puts "<!DOCTYPE HTML>"
        out.puts "<head>"
        out.puts "<style>"
        out.puts "p {\n\tmargin: 4px;\n} body {\n\tbackground-color: #eee;\n}\nsvg {\n\tborder: 1px solid black;\n\twidth: 550px;\n\theight: 550px;\n}\nsvg g circle {\n\tz-index: 10;\n}\nsvg g text {\n\tfont-size: 10px;\n\tcolor:#555;\n}\nsvg g line {\n\tstroke:rgb(0,0,0);\n\tstroke-width:2; \n\tz-index: -1;\n}\n.b{\n\tstroke: rgb(255,255,255);\n\tstroke-width: 1;\n} "
        out.puts "</style>"
        out.puts "</head>"
        out.puts "<body>"
        out.puts "<svg>"
        
        li = 50

        out.puts "<g>"


        ref.each.with_index { |city, index|
            top = 103
            x = city.x.to_f
            x *= 5
            y = top - city.y.to_f
            y *= 5
            out.puts("<circle cx=\"#{x}\" cy=\"#{y}\" r=\"6\" stroke =\"black\" stroke-width=\"1\" fill=\"black\"> <title>id: #{city.id} \nx: #{city.x} \ny: #{city.y}</title> </circle>")
        }

        for a in print_array do
            a.each.with_index { |city, index|
                if index == 0
                    next
                end
                top = 103
                prev_x = a[index-1].x.to_f * 5
                prev_y = (top - a[index-1].y.to_f) * 5
                x = city.x.to_f
                x *= 5
                y = top - city.y.to_f
                y *= 5
                out.puts("<text x=\"#{x+5}\" y=\"#{y-5}\">#{city.id}</text>")
                out.puts("<line x1=\"#{x}\" y1=\"#{y}\" x2=\"#{prev_x}\" y2=\"#{prev_y}\"> <title>#{a[index-1].id} to #{city.id}</title> </line>")
            }
        end

        out.puts "</g>"
        out.puts "</svg>"
        out.puts "<div style=\"width: 300px; height: auto; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word; \">"
        out.puts "<p style = \"font-size: 12px; color: #666;\">hover over nodes/lines for info</p><p>"
        out.puts "WOC CHAIN (ALL)"
        out.puts "</p>"
        out.puts "<p>"
        out.print "| -"
        out.puts "|"
        out.puts "</p>"
        out.puts "</div>"
        out.puts "</body>"
        $outputcount += 1
        count +=1
    # end
end

#untangle woc chain connections
def dekink(array)
    size = array.length
    result = array.dup
    temp = array.dup
    tempsize = get_total_distance(temp)
    loopcheck = nil

    until loopcheck == tempsize
        loopcheck = tempsize.dup
        until (size <= 3)
            # puts "doing: size = #{size} :: #{tempsize}"
            for a in (0...result.length)
                temp = mutate_rsm_alt(result, a, (a+size) % result.length)
                x = get_total_distance(temp)
                if x < tempsize
                    result = temp
                    tempsize = x
                    # output_file(result)
                end
            end
            size -= 1
        end

        (loopcheck == tempsize) ? (break) : ()
        loopcheck = tempsize

        until (size >= array.length)
            # puts "doing: size = #{size} :: #{tempsize}"
            for a in (0...result.length)
                temp = mutate_rsm_alt(result, a, (a+size) % result.length)
                x = get_total_distance(temp)
                if x < tempsize
                    result = temp
                    tempsize = x
                end
            end
            size += 1
        end

        (loopcheck == tempsize) ? (break) : ()
    end
    return temp
end

# main ---
set_input_filename()
elapsed_time = Time.now

#make first generation
city_array = get_cities()
# print_city_ids(city_array)

#population total dist
population = []

#random starting population
$pop_count.times do
	x = Path.new(city_array.dup, nil)
	y = scramble_array(x.array)
	x.dist = get_total_distance(y)
    x.array = y
	population.insert(-1, x)
end

puts "Population made."

#the sum of all distances, used for weighted selection
nextgen = []

#finding best solution before running
ah2 = ALargeNumber
population.each { |p|
    if p.dist < ah2
        ah2 = p.dist
    end
}

#inits
num = 1
mut = 0
best = ALargeNumber
flag = false
thread_array = []
weighted_results = []

puts "Begin Genetic Algo: "

#start gen loop
$gen_count.times do

    #children creation (20% of pop)
    ($pop_count/10).times do
        weighted_results.clear
        until weighted_results[1] != nil
            weighted_results = weighted_rand(population)
        end

        p1 = weighted_results[0]
        p2 = weighted_results[1]

        if (population[p1].dist == population[p2].dist)
            x = Path.new(population[p1].array, population[p1].dist)
            nextgen.insert(-1, x)
            x = Path.new(population[p2].array, population[p2].dist)
            nextgen.insert(-1, x)
        else
            child_array = ox1_mod(population[p2].array, population[p1].array)
            x = Path.new(child_array[0], get_total_distance(child_array[0]))
            nextgen.insert(-1, x)
            x = Path.new(child_array[1], get_total_distance(child_array[1]))
            nextgen.insert(-1, x)
        end
    end

    #roll for mutation
    if rng_mut() == true
        r = rand(population.length)
        population[r].array = mutate_rsm(population[r].array)
        mut += 1
    end 

    #removal of worst solutions (same number as children)
    ($pop_count/5).times do
      y = population.index(population.max_by{ |x| x.dist })
      population.delete_at(y)
    end

    #adding children to population
    population = population + nextgen
    nextgen.clear

    #every 10 gens, output file
    if (num % 10) == 0
        a = population.min_by { |x| x.dist }
        a = population[population.index(a)]
        output_file(a)
    end

    #generation counter + progress bar
    num += 1
    printf("\rProg: [%-35s] | time: %ds | gen: %d/%d | best: %d ", ("█" * ((num*35)/$gen_count)), (Time.now - elapsed_time), num-1, $gen_count, $td)
end

#last output file
a = population.min_by { |x| x.dist }
a = population[population.index(a)]
output_file(a)
puts

#finding best 
ah = ALargeNumber
ah_array = nil
population.each { |p|
    if p.dist < ah
        ah = p.dist
        ah_array = p.array
    end
}

puts "best @ begin of genetic algo - #{ah2}"
puts "best @ end of genetic algo - #{ah}"
print "Best Path:   "
print_city_ids(ah_array)

#begin wisdom of crowds -------------------------------------------------------------------
toppop = []

#toppop is 10% of the total population in G.A.
($pop_count/10).times do
    grab = population.delete_at(population.index(population.min_by{ |x| x.dist }))
    toppop.insert(-1, grab)
end

path_length = toppop[0].array.length   

#agreement matrix init.
topmatrix = make_matrix(path_length)

#agreement matrix values set
toppop.each.with_index { |a, aindex|
    a.array.each.with_index { |b, bindex|
        topmatrix[b.id.to_i - 1][a.array[(bindex + 1) % path_length].id.to_i - 1] += 1
    }
}

# print_matrix(topmatrix)
final = []

#chain creation loop -- if tolerence is too high, rerun with lower tolerence until chains satisfy
until !final.empty? 
    #chain creation
    result = [] #array of arrays (groups of "chains")
    topmatrix.each.with_index { |row, from|
        to = weighted_matrix(row)
        if result.empty?
            x = []
            x.insert(-1, from)     #from index (id - 1)
            x.insert(-1, to)       #to index (id - 1)
            (to != -1) ? (result.insert(-1, x)) : ()   #insert start of chain
        else
            for chain in result do
                if chain.last == -1
                    #do nothing
                    break
                elsif (chain[1...chain.length-1] & [to, from]).any?    
                    #can't connect to middle of chain -- do nothing
                    break
                elsif chain.first == to
                    chain.unshift(from)
                    break
                elsif chain.last == from
                    chain.push(to)
                    break
                elsif chain == result.last
                    result.insert(-1, [from, to])
                    break
                end
            end
        end         
    }

    #removing invalid chains (no value above woc ratio in matrix row)
    bresult = []
    for chain in result do
        (chain.last == -1) ? () : (bresult.insert(-1, chain))
    end

    result.clear
    result = bresult.dup

    puts "Chains created. #{Time.now - elapsed_time} sec."

    xresult = []
    ri = 0
    rflag = false

    #combining chains
    until result.empty?
        front = result.delete_at(0)
        if result.empty?
            final.push(front)
            break
        else
            until result.empty?
                grab = result.delete_at(0)
                if front.first == grab.last
                    x = (grab[0...grab.length-1].dup + front.dup)
                    front = x
                    rflag = true
                elsif front.last == grab.first
                    x = (front.dup + grab[1..grab.length].dup)
                    front = x
                    rflag = true
                elsif (!front.include? grab.first) || (!front.include? grab.last)
                    xresult.push(grab)
                end
            end
        end

        if rflag == false
            final.push(front)
        else
            xresult.push(front)
        end
        
        rflag = false
        
        result = xresult.dup
        xresult.clear
    end

    #if no chains exist, lower tolerance
    if final.empty?
        $accept_ratio -= 0.05
    end
end

#if all chains agree, the last and first elements of the chain will be the same, remove one
if (final.length == 1 && final[0].first == final[0].last)
    final[0].pop
end

#show chains in gui
output_file_woc(final, city_array)

#dekink chains
#turn them into actual city arrays first lol
lol_count = 0
temp_array = []
for array in final do
    temp_array[lol_count] = []
    for x in array do
        temp_array[lol_count].insert(-1, city_array[x].dup)
    end
    lol_count += 1
end
final = temp_array

puts "Dekinking... #{Time.now - elapsed_time} sec."

#ok now dekink
#find what points are remaining
union = []
for a in 0...final.length do
    union = union + final[a]
end
union = dekink(union)

puts "Dekinked. #{Time.now - elapsed_time} sec."

#print arrays to be used in greedy algorithm
puts "union: [city-array]"
print_city_ids(union)

#set theory, baby
whats_left = (city_array - (city_array & (union)))

puts "whats left: [points]"
print_city_ids(whats_left)
puts

elapsed_time = Time.now - elapsed_time  #timer for report graph
puts "\nCompleted in " + elapsed_time.to_s + " seconds."
