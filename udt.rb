#!/usr/bin/env ruby
#This will create vim higlight groups for typedefs, structs, and classes in C++ source code.

if ENV['SE_CORE']
	$: << ENV['SE_CORE']
end

#requires
require 'se_core'
require 'getoptlong'

#{{{
def print_help
	puts "Usage:  csyntax_expander.rb [options]"
	puts "Options:"
	puts "-r\t\t\tRecurse subdirectories"
	puts "--stdout\t\tPrint output to stdout, Default"
	puts "--output-file  -o {file}  Print output to file"
	puts "--help  -h\t\tPrint this message"
end
#}}}
#{{{
def main

	opts = GetoptLong.new
	opts.ordering = GetoptLong::PERMUTE
	opts.set_options(
			  ['-r',				  GetoptLong::NO_ARGUMENT],
			  ['--stdout', 			  GetoptLong::NO_ARGUMENT],
			  ['--output-file',	'-o', GetoptLong::OPTIONAL_ARGUMENT],
			  ['--help', 		'-h', GetoptLong::NO_ARGUMENT]
			  )

	#set the defaults
	files = Dir["*.h"]
	out = $stdout
	skip = false

	#{{{
	opts.each { |opt, arg|
		case opt 
			when /-r/
				files = Dir["**/*.h"]
			when /-o/
				if arg == ''
					out = File.open("cyn_ext.vim", File::CREAT|File::TRUNC|File::WRONLY)
				else
					out = File.open(arg, File::CREAT|File::TRUNC|File::WRONLY)
				end
			when /-h/
				print_help
				skip = true
		end
	}
	#}}}
	#{{{
	if not skip
		parser = FindKeywords.new
		writer = Highlighter.new
		files.each { |arg|
			parser.parse arg
		}
		writer.write_syn { |str|
			out.puts str
		}
		writer.write_hi { |str|
			out.puts str
		}
	end
	#}}}
end
#}}}

main
