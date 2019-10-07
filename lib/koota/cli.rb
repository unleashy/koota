# frozen_string_literal: true

require 'koota'
require 'koota/file_parser'

require 'slop'

module Slop
  # @api private
  class RangeOption < Option
    def call(value)
      split = value.split(',')

      raise Slop::Error, 'invalid range argument' if split.length.zero? || split.length > 2

      split.map!(&:to_i)
      split.length == 1 ? split[0] : split[0]..split[1]
    end
  end
end

module Koota
  # This class handles the command-line interface to Koota.
  class CLI
    def initialize(program_name: $PROGRAM_NAME, output: $stdout)
      @file_parser = Koota::FileParser.new
      @generator   = Koota::Generator.new
      @output      = output
      @opts        = build_opts(program_name)
    end

    def call(argv = ARGV)
      result = @opts.parse(argv)

      if result.help?
        @output.puts @opts
        return true
      elsif result.version?
        @output.puts "koota v#{VERSION}"
        return true
      end

      raise Slop::Error, 'missing input file(s)' if result.args.empty?

      process(result.args, result.to_h)
    rescue Slop::Error => e
      @output.puts "error: #{e.message}"
      @output.puts @opts

      false
    end

    private

    def process(files, options)
      is_one_file = files.length == 1

      return false unless verify_existence(files)

      files.each_with_index do |file, i|
        contents = File.read(file, mode: 'rb', encoding: 'UTF-8')
        pattern  = @file_parser.call(contents)

        @output.puts "--- #{file}" unless is_one_file
        @output.puts @generator.call(pattern, options).join(options[:word_separator])
        @output.puts unless is_one_file || i == files.length - 1
      end

      true
    end

    def verify_existence(files)
      result = true

      files.each do |file|
        unless File.exist?(file)
          @output.puts "error: could not find file '#{file}'"
          result = false
        end
      end

      result
    end

    def build_opts(program_name)
      banner = <<~BANNER.strip
        koota v#{VERSION} -- a word generator

        usage: #{program_name} [options] FILE ...
      BANNER

      Slop::Options.new(banner: banner) do |o|
        o.bool '-d',
               '--duplicates',
               'whether or not to keep duplicate words (default: false)',
               default: false

        o.range '-s',
                '--syllables',
                'the amount of syllables to generate (default: 1)',
                default: 1

        o.string '-r',
                 '--syllable-separator',
                 'the string separating each syllable (default: empty)',
                 default: ''

        o.int '-w',
              '--words',
              'the amount of words to generate (default: 100)',
              default: 100

        o.string '-p',
                 '--word-separator',
                 'the string separating each word (default: new line)',
                 default: "\n"

        o.separator "\nother options:"

        o.bool '--bytecode', 'output compiled bytecode'
        o.bool '-h', '--help', 'show help text'
        o.bool '-v', '--version', 'show version'
      end
    end
  end
end
