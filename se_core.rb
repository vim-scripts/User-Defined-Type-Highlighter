#!/usr/bin/env ruby

require 'singleton'

$typedef_group = 'cppUserTypedefs'
$struct_group = 'cppUserStructs'
$class_group = 'cppUserClasses'
$def_colors = {
	"typedef" => "guifg=white gui=bold",
	"class" => "guifg=white gui=bold",
	"struct" => "guifg=white gui=bold"
}

#{{{
class Array
	def each_group(num)
		0.step(size-1, num) { |x| yield self[x, num] }
	end
end
#}}}
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

	def initialize
		@keeper = Keywords.instance
	end

	def write_syn
		#print "to file"
		if not @keeper.typedefs?
			td = @keeper.typdefs
			td.uniq!
			td.each_group(5) { |words|
				yield "syn keyword #{$typedef_group} #{words.join(' ')}"
			}
		end

		if not @keeper.structs?
			st = @keeper.structs
			st.uniq!
			st.each_group(5) { |words|
				yield "syn keyword #{$struct_group} #{words.join(' ')}"
			}
		end

		if not @keeper.classes?
			cl = @keeper.classes
			cl.uniq!
			cl.each_group(5) { |words|
				yield "syn keyword #{$class_group} #{words.join(' ')}"
			}
		end
	end

	def write_hi(hsh=$def_colors)
		yield ''
		yield "hi cppUserTypedefs #{hsh['typedef']}"
		yield "hi cppUserStructs #{hsh['struct']}"
		yield "hi cppUserClasses #{hsh['class']}"
	end

end
#}}}
#{{{
class FindKeywords

	@@typedef = /^\s*typedef\s+.*/
	@@class = /^\s*class\s*(\w*)\s*.*/
	@@struct = /^\s*struct\s*(\w*)\s*.*/

	def initialize
		@keeper = Keywords.instance
	end

	#{{{
	def parse(fname)
		#p "parsing"
		File.open(fname, File::RDONLY) { |file|
			in_struct = false
			matched_typedef = false
			file.each { |line|
				case line
					when @@typedef
						#p line
						if line =~ /(struct|enum|union)/
							in_struct = true
						else
							parse_typedef line
						end
					when @@class
						@keeper.add_class $1
					when @@struct
						@keeper.add_struct $1
					when in_struct
						#p line
						in_struct = line =~ /}(.*);/
						if not in_struct
							$1.split(',').each { |type|
								@keeper.add_typedef type
							}
						end
				end
			}
		}
	end
	#}}}

	def parse_typedef(tdstring)
		#p tdstring
		md = tdstring =~ /typedef\s*.*\s+(.+?);/
		m = $1
		if m
			if not m =~ /[()*]/
				@keeper.add_typedef m.strip
			end
		end
	end

end
#}}}
