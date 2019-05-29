#!/usr/bin/env ruby
require 'json'
require 'net/http'
require 'optparse'
require 'ostruct'
require 'logger'
require 'open3'


class SemaphoreRegistry

  @logger = Logger.new(STDOUT)
  @logger.level = Logger::INFO

  def self.search(name,tag)
    uri = URI("https://registry.hub.docker.com/v2/repositories/semaphoreci/#{name}/tags/#{tag}/")
    puts uri
    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      body = JSON.parse(Net::HTTP.get(uri))
      @logger.info("Image found: Repository: #{name}, Tag: #{body['name']}")
      return true
    elsif response.is_a?(Net::HTTPNotFound)
      @logger.info("Image not found")
      return false
    else
      @logger.error response
      return false
    end
  end

  def self.run(cmd)
    Open3.popen2(cmd) do |stdin, stdout_stderr, wait_thr|
      stdout_stderr.each {|l| @logger.info l }
      exit_status = wait_thr.value
      unless exit_status.success?
        abort "FAILED !!! #{cmd}"
      end
    end
  end

  def self.build(dir,rebuild,test)
    files = Dir.entries(dir).select {|f| !File.directory? f }
    files.each do |f|
      # e.g Dockerfile-golang-1.9
      parts = f.split("-")
      repo = parts[1]
      # Get tag from filename - 1.9-node
      version = parts[2]
      tag = parts[2...parts.length].map { |k| k }.join("-")
      next if self.search(repo,tag) && !rebuild
      @logger.info("Rebuilding all Images") if rebuild
      @logger.info("Building #{repo} #{tag}")
      self.run("docker build -t semaphoreci/#{repo}:#{tag} -f #{dir}/#{f} #{dir}")
      @logger.info("Running Tests")
      self.run("GOSS_FILES_PATH=tests/goss GOSS_VARS=vars.yaml GOSS_FILES_STRATEGY=cp dgoss run -e PACKAGE=\"#{repo}\" -e VERSION=\"#{version}\" semaphoreci/#{repo}:#{tag} /bin/sleep 3600")
      if !test
        @logger.info("Push to Dockerhub")
        self.run("docker push semaphoreci/#{repo}:#{tag}")
      end
      @logger.info("Cleanup")
      self.run("docker system prune -a -f")
    end
  end

end

options = OpenStruct.new
parser = OptionParser.new do |opts|
  opts.banner = 'Usage: %s [options]' % $0
  opts.on('-d', '--dir DIR', 'Dockerfiles dir.') { |o| options[:dir] = o }
  opts.on('-t', '--test', 'Only test images with dgoss') { |o| options[:test] = o }
  opts.on('-r', '--rebuild', 'Rebuild all images') { |o| options[:rebuild] = o }
  opts.on_tail("-h", "--help", "Show help") do
    puts opts
    exit 1
  end
end

args = parser.parse!

begin
  mandatory = [:dir]
  missing = mandatory.select{ |param| options[param].nil? }
  raise OptionParser::MissingArgument, missing.join(', ') unless missing.empty?
rescue OptionParser::ParseError => e
  puts e
  puts parser
  exit 1
end

SemaphoreRegistry.build(options[:dir],options[:rebuild],options[:test])
