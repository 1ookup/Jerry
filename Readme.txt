1. 运行环境
安装ruby 
windows 下载ruby-installer
linux 下载rvm ruby版本控制
安装之后
cd 到jerry目录
执行
> bundle config mirror.https://rubygems.org https://ruby.taobao.org   # (GFW不能连接https://rubygems.org)
> gem install bundle 
> bundle install
即可运行 Jerry

2. 参数说明
-r  加载一个攻击插件   针对不同的漏洞，口令爆破只需要写一个rb脚本(这个脚本也可以独立运行针对一个目标)。 Jerry.rb负责加载脚本批量跑
-i  ip字典。zmap 扫描结果保存的文件。
-u  username 字典(如果加载的攻击插件是弱口令爆破类， 需要这个参数， 漏洞利用类 不需要)
-p  password 字典(如果加载的攻击插件是弱口令爆破类， 需要这个参数， 漏洞利用类 不需要)
－t 线程数量

注:
-i ip字典， 只支持端口扫描软件扫描结果。
格式 :
192.168.1.1
192.168.1.2
192.168.1.5
192.168.1.11
192.168.1.16

如zmap的扫描结果
./zmap -p 8080 192.168.0.0/12 -B 10M -o 8080.txt

masscan扫描结果需要处理下
masscan -p 8080 172.31.31.0/12 -oX /tmp/mas_8080.xml
命令行执行> irb
irb> infile = "/tmp/mas_8080.log"; outfile = "/tmp/8080.txt";require 'rexml/document';addrs = []; REXML::Document.new(File.open(infile)).each_element("nmaprun/host/address") { |e| addr = e.attributes['addr']; addrs << addr}; File.open(outfile,"w") { |f| f.puts addrs.join("\n"); }
irb> exit
结果保存在/tmp/8080.txt 

3. 实例
ruby jerry.rb -r tomcat.rb -i /tmp/8080.txt -t 20
ruby jerry.rb -r ssh_login.rb -i /tmp/22.txt -u /tmp/user.txt -p /tmp/pass.txt -t 50