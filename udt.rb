#!/usr/bin/env ruby
#This will create vim higlight groups for typedefs, structs, and classes in C++ source code.

# Add paths to possible locations for se_core.rb.  This is more robust than
# the previous set up.  It will work 'out-of-box', without requiring the user
# to set env vars.  The prefered method is still to set the env var.
$: << "#{ENV['HOME']}/.vim" if FileTest.exist? "#{ENV['HOME']}/.vim/se_core.rb"
$: << ENV['SE_CORE'] if ENV['SE_CORE']


#requires
require 'se_core'

# Removing the dependence on a non-core ruby pkg.
#require 'getoptlong'

#{{{
def print_help
	puts "Usage:  udt_highlight.rb [options]"
	puts "Options:"
	puts "-r\t\t\tRecurse subdirectories"
	puts "--stdout\t\tPrint output to stdout, Default"
	puts "--output-file  -o {file}  Print output to file"
	puts "--help  -h\t\tPrint this message"
end
#}}}
#{{{
def main

	#set the defaults for the options
	files = Dir["*.h"]
	out = $stdout
	skip = false

	#{{{
	$*.each_index { |idx|
		opt = $*[idx]
 		case opt 
 			when /-r/
 				files = Dir["**/*.h"]
 			when /-o/
				arg = $*[idx.succ] unless $*[idx.succ] =~ /-/
 				if arg
 					out = File.open(arg, File::CREAT|File::TRUNC|File::WRONLY)
 				else
 					out = File.open("cyn_ext.vim", File::CREAT|File::TRUNC|File::WRONLY)
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
