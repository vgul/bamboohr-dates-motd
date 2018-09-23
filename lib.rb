
require 'getoptlong'
require 'fileutils'

def stored_feeds 
    return <<EOS
#Anniv:https://company.bamboohr.com/feeds/feed.php?id=somelink1
#Birthdays:https://company.bamboohr.com/feeds/feed.php?id=somelink2
#CompanyHolidays:https://company.bamboohr.com/feeds/feed.php?id=somelink3
#Whoisout:https://company.bamboohr.com/feeds/feed.php?id=somelink4
EOS
end

def separate( text )
  cur_str = text

  c = 0
  list = []
  loop do
  
    p = cur_str.match(/(.*?)(BEGIN:VEVENT.*?END:VEVENT)(.*)/m)
    break unless p 
    c = c + 1
    before, cur, last0 =  p.captures

    event = handle_ical(cur)
    list.push(event)

    cur_str = last0
    #break if c == 2
  end
  list
end

def handle_ical(text)
  event = {}

  text.split(/\n/).each do |l|
    l.strip!
    
    next if l.match(/VEVENT$/)

    var,value = l.match(/(.*?):(.*)/).captures

    var.gsub!(';VALUE=DATE','')

    #puts "#{var} : #{value}<"
    event[var] = value
  end

  unless event.has_key?('CATEGORIES')
    raise "No key CATEGORIES for #{event}"
  else
    summary = event['SUMMARY']
    case event['CATEGORIES']
      when 'Anniversaries'
 
        match = summary.match(/(.*)\s+\(\s*(\d+)\s*yrs?\s*\)/)
        unless match 
          pp event
          raise "\nUnexpected SUMMARY #{summary}"
        else
          person, years = match.captures
          event['item'] = person
          event['info'] = sprintf 'Ann_%d', years
        end
      when 'Birthdays'
        match = summary.match(/(.*)\s+-.*/)
        unless match 
          pp event
          raise "\nUnexpected SUMMARY #{summary}"
        else
          person = match.captures[0]
          #puts person
          event['item'] = person
          event['info'] = sprintf 'BD'
        end

      when 'Who\'s Out'
        #puts summary
        # Petr Ivanoff (Paid Vacation - 9 days)
        match = summary.match(/(.*)\s+\(\s*(.*)\s+-\s+(.*)\s+days?\)/)
        unless match.nil?
          person, type, days = match.captures
          case type
            when 'Paid Vacation'
              type = 'PV'
            when 'Hospitalization'
              type = 'Ill'
            when 'Working OOO'
              type = 'OOO'
            when 'Day off'
              type = 'Off'
          end
          event['item'] = person
          event['info'] = sprintf "%s_%s", type, days
        else
          pp event
          raise "\nUnexpected SUMMARY #{summary}"
        end

      when 'Company Holidays'
        match = summary.match(/Company Holiday\s+-\s+(.*)/)
        unless match
          pp event
          raise "\nUnexpected SUMMARY #{summary}"
        else
          holiday = match.captures
          event['item'] = holiday[0]
          event['info'] = sprintf 'HD'
        end

        if diff_days(event['DTEND'],event['DTSTART']).to_i ==1
          event.delete('DTEND')
        end

      else
        puts 'empty:'+ event['CATEGORIES']
    end
  end
  event
end

@file_num=0
def store_feed( string )
    @file_num = @file_num + 1
    input_data = string.match(/(.*?):?(https?:.*)/)
    name0, url = input_data.captures
    name0  = @file_num if name0.empty?

#    puts name0, url
    cache_file = Sugar.cache_index_file( name0 )
#    puts cache_file

    cmd = nil
    if @opts[:debug]
      cmd = "cat #{cache_file}"
    else
      proxy = "https_proxy=http://user:pass@localhost:3149"
      proxy = ""
      cmd = "#{proxy} \\curl -s  #{url} | tee #{cache_file}"
    end

    separate( %x{ #{cmd} } )
end

module Sugar
  @@scriptname = nil
  @@realdir = nil

  @@cache_directory = nil
  attr_reader :cache_directory

  def self.cache_index_dir #(param)
    unless @@cache_directory
      short_script_name = self.scriptname_short

      #puts short_script_name

      success = false

      [ "/var/cache/#{short_script_name}",
        "#{self.realdir}",
        "/tmp/#{short_script_name}",
      ].each do |p|
        p = p + "/Cache"

        if File.directory?(p) and File.writable?(p)
          @@cache_directory = p
          success = true
          break
        else
          begin
            FileUtils.mkdir_p(p)
            FileUtils.touch("#{p}/someFile")
            FileUtils.rm( "#{p}/someFile" )
            @@cache_directory = p
            success = true
            break
          rescue
            STDERR.puts "WARN: could not create/access #{p}. Create pls."
          end 
        end
      end
      raise 'could not set cache directory' unless success
    end
    @@cache_directory

  end

  def self.cache_index_file(name)

    self.cache_index_dir unless @@cache_directory

    "#{@@cache_directory}/#{name}.ical.#{%x{date +%H}.chop}"

  end 

  def self.scriptname_short
    @@scriptname ||= File.basename(File.realpath($0))
    #pp $0, @@scriptname
    @@scriptname.gsub(/\..*/,'')
  end

  def self.realdir
    @@realdir ||= File.dirname(File.realpath($0))
  end

end

module HCL
  def self.handle_command_line 
    opts = GetoptLong.new(
      [ '--debug',      '-d', GetoptLong::NO_ARGUMENT ],
      [ '--skip-check', '-s', GetoptLong::NO_ARGUMENT ],
      [ '--monitor',    '-m', GetoptLong::REQUIRED_ARGUMENT ],
#      [ '--verbose', '-v',    GetoptLong::NO_ARGUMENT ],
      [ '--help', '-h',       GetoptLong::NO_ARGUMENT ]
    )

    options = {
        debug: false,
        skip_check: false,
        monitor_days: 4,
#        pages: 3
        #language: 'ruby' # default
    }

    opts.each do | opt, arg |

      case opt
        when '--debug'
          options[:debug] = true
        when '--skip-check'
          options[:skip_check] = true
        when '--monitor'
          options[:monitor_days] = arg.to_i
        when '--help'
  #-v --verbose       subj.
          puts <<-EOF

Complact specific iCal representations
  #{Sugar.scriptname_short} [OPTION] 

  -s --skip-check    show all events; without date filter
  -m --monitor DAYS  how many days to monitor; default 4

  -d --debug         debug mode. use cache instead load pages
  -h --help          show help

  Outputs:

          EOF
          exit 0
      end

    end

    options
  end
   
end

def diff_days( date_compressed, date2=false )
  
  date01 = [ date_compressed[0..3], 
             date_compressed[4..5],
             date_compressed[6..7] ].join('-')

  secs = %x{ #{TZ} date -d '#{date01}' +%s }.chop.to_i
  unless date2
    secs_to_diff = @now_secs
  else
    date02 = [ date2[0..3], 
               date2[4..5],
               date2[6..7] ].join('-')

    secs_to_diff = %x{ #{TZ} date -d '#{date02}' +%s }.
                    chop.to_i
  end
  (( secs - secs_to_diff ) / (60*60*24)).to_s
end

