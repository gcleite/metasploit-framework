#!/usr/bin/env ruby

msfbase = __FILE__
while File.symlink?(msfbase)
  msfbase = File.expand_path(File.readlink(msfbase), File.dirname(msfbase))
end
$:.unshift(File.expand_path(File.join(File.dirname(msfbase), '..', 'lib')))
require 'msfenv'
require 'rex'
require 'msf/core'
require 'msf/base'
require 'optparse'

module Jsobfu
  class OptsConsole
    def self.parse(args)
      options = {}
      parser = OptionParser.new do |opt|
        opt.banner = "Usage: #{__FILE__} [options]"
        opt.separator ''
        opt.separator 'Specific options:'

        opt.on('-t', '--iteration <Fixnum>', "Number of times to obfuscate the JavaScript") do |v|
          options[:iteration] = v
        end

        opt.on('-i', '--input <String>', "The JavaScript file you want to obfuscate (default=1)") do |v|
          options[:input] = v
        end

        opt.on('-o', '--output <String>', "Save the obfuscated file as") do |v|
          options[:output] = v
        end

        opt.on_tail('-h', '--help', 'Show this message') do
          $stdout.puts opt
          exit
        end
      end

      parser.parse!(args)

      if options.empty?
        raise OptionParser::MissingArgument, 'No options set, try -h for usage'
      elsif options[:iteration] && options[:iteration] !~ /^\d+$/
        raise OptionParser::InvalidOption, "#{options[:format]} is not a number"
      elsif !::File.exists?(options[:input].to_s)
        raise OptionParser::InvalidOption, "Cannot find: #{options[:input]}"
      end

      options[:iteration] = 1 unless options[:iteration]

      options
    end
  end

  class Driver
    def initialize
      begin
        @opts = OptsConsole.parse(ARGV)
      rescue OptionParser::ParseError => e
        $stderr.puts "[x] #{e.message}"
        exit
      end
    end

    def run
      original_js = read_js(@opts[:input])
      js = ::Rex::Exploitation::JSObfu.new(original_js)
      js.obfuscate(:iterations=>@opts[:iteration].to_i)
      js = js.to_s

      output_stream = $stdout
      output_stream.binmode
      output_stream.write js
      $stderr.puts

      if @opts[:output]
        save_as(js, @opts[:output])
      end
    end

    private

    def read_js(path)
      js = ::File.open(path, 'rb') { |f| js = f.read }
      js
    end

    def save_as(js, outfile)
      File.open(outfile, 'wb') do |f|
        f.write(js)
      end

      $stderr.puts
      $stderr.puts "File saved as: #{outfile}"
    end

  end
end


if __FILE__ == $PROGRAM_NAME
  driver = Jsobfu::Driver.new
  driver.run
end