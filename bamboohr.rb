
require 'pp'

@now_secs = Time.now.to_i
@maxahead = 14 # days to look ahead

@monitor_days_ago = 4

TZ = "TZ=UTC"
@curdate = %x{ #{TZ} date -d @#{@now_secs} +'%F' }.chop.gsub('-','')
@maxahead = %x{ #{TZ} date -d '@#{(@now_secs + @maxahead*60*60*24).to_i}' +'%F' }.chop.gsub('-','')

require_relative 'lib'
@opts = HCL.handle_command_line


feed_list = ENV['ICAL_FEEDS'] || stored_feeds

list = []
feed_list.split( /;|\n/ ).each do |feed|
  next if feed.match(/^\s*#/)

  list.push( store_feed( feed ) )

end

list.flatten!

list.sort_by{|e| e['DTSTART']}.each do |i|

  dtend = nil
  skip_flag = false

  if( i.has_key?('DTEND') )
    dtend = i['DTEND']
  end

  if( diff_days(i['DTSTART']).to_i.abs > @opts[:monitor_days] )
    skip_flag = true
  end
  
  if( skip_flag and dtend and diff_days(dtend).to_i.abs < 
    @monitor_days_ago )
    skip_flag = false
  end

  unless @opts[:skip_check]
    next if skip_flag
  end

  item = i['item']
  #ie = list.select{ |e| e['item'] == item }[0]

  #printf "%40s #{@curdate} : #{p['CATEGORIES']} ",  p
  printf "%s;%s;%s", i['info'], diff_days(i['DTSTART']), item

  time_info = " #{i['DTSTART']}"
  if i.has_key?('DTEND')
    print ";" + diff_days( i['DTEND'] )
    time_info = "#{time_info} #{i['DTEND']}"
  end

  print time_info
  #exit 0
  puts
  #person event 
  next
  puts "ie:"
  pp ie
#exit 0
  #puts ie['SUMMARY']
  puts ie['info']
  exit 0
  #puts   pa.map{ |e| "#{e['DTSTART']}-#{e['DTEND']}" }.join(' ')
  #print " #{ie['CATEGORIES']} "
  print "; #{ie['info']}; "
exit 0
  print  diff_days( ie['DTSTART'] ) + " ** #{ie['DTSTART']}"

  if ie.has_key?('DTEND')
      puts "-#{pe['DTEND']}" + ' ** ' + diff_days( pe['DTEND'] )
  end
  puts

end

exit 0
#pp person_list
exit 0
puts feed_list
exit 0



def Zhandle_atom(text)
  tmp = {}
  text.split(/\n/).each do |l|
    l.strip!
    #puts "L:#{l}"
    
    next if l.match(/VEVENT$/)

    var,value = l.match(/(.*?):(.*)/).captures

    if var == 'SUMMARY'
      person, summary0 = value.match(/(.*)\s+\((.*)\)/).captures

      #puts  person
      tmp['person'] = person
      tmp['summary0'] = summary0

      summary1_match = summary0.match(/(.*\S)\s*-\s*(\d+)\s+days?/)
      if summary1_match 
        type_long, duration = summary1_match.captures
      else
        type_long = duration = 'unknown'
      end

      tmp['type_long'] = type_long
      tmp['duration'] = duration
    end
    var.gsub!(';VALUE=DATE','')

    #puts "#{var} : #{value}<"
    tmp[var] = value
  end
  tmp
  #puts %x{ echo "#{text}" | grep SUMMARY }
end





#cur_str = data
#c = 0


#puts curdate
#puts maxahead
#exit 0

list = []
loop do

  p = cur_str.match(/(.*?)(BEGIN:VEVENT.*?END:VEVENT)(.*)/m)
  break unless p 
  c = c + 1
  before, cur, last0 =  p.captures
  #puts c

  event = handle_atom(cur)

  # cut earlier and older
  case event['DTEND'] <=> curdate
    when 0,1
      case event['DTSTART'] <=> maxahead
        when -1
          list.push( event )
      end
  end

  cur_str = last0

end


person_list = list.map{|e|  e['person'] }.uniq #.sort


#pp person_list
#pp list
