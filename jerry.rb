#!/usr/bin/env ruby
require 'optparse'
require 'awesome_print'
require 'ruby-progressbar'

$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__))  
Thread.abort_on_exception = true

options = {}
ARGV << '-h' if ARGV.empty?
option_parser = OptionParser.new do |opts|
	opts.banner = 'here is help massages of the command line tool.'

	options[:exploit] = false
	opts.on('-e', '--exploit', 'default verify vuln') do
		options[:exploit] = true
	end

	opts.on('-r FILE', '--require FILE', 'The PoC file') do |value|
		options[:require] = value
	end

	opts.on('-i FILE', '--ipList FILE', 'The Target IP List') do |value|
		options[:iplist] = value
	end

	opts.on('-u FILE', '--userfile FILE', 'The username file') do |value|
		options[:userfile] = value
	end

	opts.on('-p FILE', '--passfile FILE', 'The password file') do |value|
		options[:passfile] = value
	end

	options[:threads] = 1
	opts.on('-t NUM', '--thread NUM', 'The num of threads') do |value|
		options[:threads] = value.to_i
	end
end.parse!

#puts options.inspect
# 检查配置项
if options[:iplist].nil? or not File.exist?(options[:iplist])
	options[:iplist] ||= "iplist"
	puts "Error: #{options[:iplist]} is not exist." 
	exit
end

class Jerry
	attr_accessor :options
	def initialize(options)
		@options = options
		@threads = []
		@ip_queue = Queue.new
		@pass_array = []
		@progressbar = ProgressBar.create(:title => "Jerry", :format => '%a |%b>>%i| %p%% %t')
		@mutex=Mutex.new 
		requireExploit
		fillQueue
		@queue_num = @ip_queue.size.to_f
	end

	def fillQueue
		# 填充ip列队
		File.read(@options[:iplist]).split("\n").each do |ip|
			@ip_queue.push ip
		end
		# 填充密码列队
		begin
			File.read(@options[:userfile]).split("\n").each do |user|
				user = user.chomp
				next if user == "" or user.nil?
				File.read(@options[:passfile]).split("\n").each do |pass|
					pass = pass.chomp
					next if pass == "" or pass.nil?
					@pass_array << {user: user, pass: pass}
				end
			end
		rescue
			#puts "Error: #{$!}"
		end
	end

	def requireExploit
		begin
			require @options[:require]
			@vuln_name = File.basename(@options[:require])
			return true
		rescue
			puts "Error: #{$!}"
			return false
		end
	end

	def progress
		queue_size  = @ip_queue.size == 0 ? 1 : @ip_queue.size
		@progressbar.progress = (@queue_num - queue_size)/@queue_num * 100
	end

	def run
		progress_thread = Thread.new do
			while true
				progress;sleep(1)
			end
		end
		mutex = Mutex.new
		@options[:threads].times do
			@threads << Thread.new do 
				until @ip_queue.empty?
					ip = @ip_queue.pop
					#exp = Exploit.new({ip: ip, pass_queue: @pass_queue})
					exp = Exploit.new({ip: ip, pass_array: @pass_array, progressbar: @progressbar, mutex: mutex})
					next if not exp.distinguish_server
					flag, msg = @options[:exploit] ? exp.exploit : exp.verify
					@progressbar.log msg ||= "#{ip} has #{@vuln_name} vuln" if flag
				end
			end
		end
		@threads.each {|t| t.join}
		Thread.kill(progress_thread)
		@progressbar.progress = 100
	end
end

class Exploit
	def initialize(options)
		@options = options
	end

	def distinguish_server
		# 识别服务，是否是需要的服务
		true
	end

	def verify
		# 验证是否存在漏洞
		puts "verify"
	end

	def exploit
		# 验证漏洞同时getshell
		puts "exploit"
	end
end

Jerry.new(options).run