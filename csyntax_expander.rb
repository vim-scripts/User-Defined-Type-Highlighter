#!/usr/bin/env ruby
#This will create vim higlight groups for typedefs, structs, and classes in C++ source code.

require 'singleton'
require 'getoptlong.rb'

$typedef_group = 'cppUserTypedefs'
$struct_group = 'cppUserStructs'
$class_group = 'cppUserClasses'

#{{{
class Keywords
	include Singleton

	attr_reader :typdefs, :structs, :classes

	def initialize
		@typdefs = Array.new
		@structs = Array.new
		@classes = Array.new
	end

	def add_typedef(word)
		@typdefs << word
	end

	def add_struct(word)
		@structs << word
	end

	def add_class(word)
		@classes << word
	end

	def typedefs?
		@typdefs.empty?
	end

	def structs?
		@structs.empty?
	end

	def classes?
		@classes.empty?
	end


end
#}}}
#{{{
class Highlighter

	def initialize(file)
		@syn_file = file
		@keeper = Keywords.instance
	end

	def write_syn
		#print "to file"
		if not @keeper.typedefs?
			td = @keeper.typdefs
			td.uniq!
			td.each { |word|
				@syn_file.puts "syn keyword #{$typedef_group} #{word}"
			}
		end

		if not @keeper.structs?
			st = @keeper.structs
			st.uniq!
			st.each { |word|
				@syn_file.puts "syn keyword #{$struct_group} #{word}"
			}
		end

		if not @keeper.classes?
			cl = @keeper.classes
			cl.uniq!
			cl.each { |word|
				@syn_file.puts "syn keyword #{$class_group} #{word}"
			}
		end
	end

	def write_hi
		@syn_file.puts
		@syn_file.puts
		@syn_file.puts "hi cppUserTypedefs guifg=white"
		@syn_file.puts "hi cppUserStructs guifg=white"
		@syn_file.puts "hi cppUserClasses guifg=white"
	end

end
#}}}
#{{{
class FindKeywords

	@@typedef = /^typedef\s*(.*?)\s+(\w*).*/
	@@class = /^class\s*(\w*)\s*.*/
	@@struct = /^struct\s*(\w*)\s*.*/

	def initialize
		@keeper = Keywords.instance
	end

	def parse(fname)
		p "parsing"
		File.open(fname, File::RDONLY) { |file|
			file.each { |line|
				case line
					when @@typedef
						@keeper.add_typedef $2
					when @@class
						@keeper.add_struct $1
					when @@struct
						@keeper.add_class $1
				end
			}
		}
	end

end
#}}}
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
			  #['--files', 		'-f', GetoptLong::REQUIRED_ARGUMENT],  #Not implemented yet, if ever
			  ['-r',				  GetoptLong::NO_ARGUMENT],
			  ['--stdout', 			  GetoptLong::NO_ARGUMENT],
			  ['--output-file',	'-o', GetoptLong::OPTIONAL_ARGUMENT],
			  ['--help', 		'-h', GetoptLong::NO_ARGUMENT]
			  )

	#set the defaults
	files = Dir["*.h"]
	out = $stdout
	skip = false

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

	if not skip
		parser = FindKeywords.new
		writer = Highlighter.new out
		files.each { |arg|
			parser.parse arg
		}
		writer.write_syn
		writer.write_hi
	end
end
#}}}

main
