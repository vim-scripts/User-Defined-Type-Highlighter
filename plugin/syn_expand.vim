"	This is a vim script to generate highlighting files for user defined types in
"	C++.
"	Maintainer:	Michael Brailsford <brailsmt@yahoo.com>
" 	Copyright:	Michael Brailsford 2002	
"	Version:	0.9beta 
"
"	This requires the vim Ruby interface.  Check :version output for "+ruby",
"	if you see it then you are good to go, otherwise recompile with the
"	--enable-rubyinterp option to configure.
"
"	Description:
"	This creates vim syntax highlighting groups for all typedefs, structs, and classes that are found
"	in C++ header files.  It creates 3 three groups, one each for typedefs, structs, and classes,
"	so if you want you can highlight those seperately.  Being that it is a beta it is not perfect.
"	Especially since I do not know all the C++ syntax for structs, typedefs nad classes.  But the
"	most common cases are taken care of.
"	
"	It has been tested on the following:
"	typedef deque<Move *> history;
"	struct Move { 
"			...
"	}
"	struct ltpos : std::binary_function...	
"	class Piece : public Base_class {
"			...
"	} 
"	
"	In which tests 'history', 'Move', 'ltpos', and 'Piece' were properly highlighted.
"	Base_class was not, since it should be defined in another header somewhere. 
"
"	Usage:
"	This file is self-contained.  You simply need to source it in you .vimrc
"	file, and then call the Generate_Highlighting() function like this 
"	":call Generate_Highlighting()".  If you want you can make it into a
"	keymapping, abbrev, or whatever you think will make it easier to run.
"	There are various options that can be set which will alter the behaviour of
"	the script.
"
"	Options:
"	g:syn_expand_recursive 
"		If g:recursive is not defined then it defaults to 0.
"		Valid setting are:	
"			0 = do not recurse directories looking for header files
"			1 = recurse directories
"	
"	g:syn_expand_tofile
"		If this is defined then the output will be written to a file which can
"		be sourced at a later time.  This is good for working on projects with
"		several developers.	
"		If it is not defined then the syntax highlighting groups will be set
"		through vim commands.	
"		The value of this var is unimportant, just define it or don't.  Setting
"		it to 50, 4000, or "foobar" makes no difference.	
"
"	g:syn_expand_outputfile
"		This contains the name of the file to which output will be written.
"		It defaults to "csyn_exp.vim".
"
"	Notes:
"	This comes with a command-line version.  It has similar options,
"	"csyntax_expander.rb --help" for details.
"
"	This was tested and created with my colorscheme, so you may or may not
"	like the colors that are the defaults.  One of the items on the todo list
"	is add vars to determine the color of the highlighting.  But that will
"	have to wait until v1.0.  Until then you can get my colorscheme at
"	vimonline.  Its midnight.vim.  I guess you can also redefine the colors
"	using ":hi", too.
"
"	Bugs:
"	I am sure that there are many.  If you find one, not that you'll need to
"	look real hard, send me a description of it and ways to reproduce it to
"	brailsmt@yahoo.com.
"
"	Todo:
"	* Add config options for colors.
"	* Add some default keymaps.
"	* Provide a mechanism to load all files generated with syn_expand.vim from
"	  the current directory towards the root of the filesystem, like with tags.
"	* Provide support for other languages... (maybe...) 

"Set up some defaults, but first make sure that they have not aleady been
"defined
if !exists("g:syn_expand_recursive")
	let g:syn_expand_recursive = 0
endif

if !exists("g:syn_expand_tofile")
endif

if !exists("g:syn_expand_outputfile")
	let g:syn_expand_outputfile = "csyn_exp.vim"
end

"This is the whole enchilada.
function! Generate_Highlighting()
"{{{
ruby << END

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

end
#}}}
#{{{
class Highlighter

	def initialize(file)
		@syn_file = file
		@keeper = Keywords.instance
	end

	def write_syn
		print "to file"
		td = @keeper.typdefs
		td.uniq!
		td.each { |word|
			@syn_file.puts "syn keyword cppUserTypedefs #{word}"
		}

		st = @keeper.structs
		st.uniq!
		st.each { |word|
			@syn_file.puts "syn keyword cppUserStructs #{word}"
		}

		cl = @keeper.classes
		cl.uniq!
		cl.each { |word|
			@syn_file.puts "syn keyword cppUserClasses #{word}"
		}
	end

	def write_hi
		@syn_file.puts
		@syn_file.puts
		@syn_file.puts "hi cppUserTypedefs guifg=white"
		@syn_file.puts "hi cppUserStructs guifg=white"
		@syn_file.puts "hi cppUserClasses guifg=white"
	end

	def write_syn_vim
	#print "vim"
		td = @keeper.typdefs
		td.uniq!
		td.each { |word|
			VIM.command "syn keyword cppUserTypedefs #{word}"
		}

		st = @keeper.structs
		st.uniq!
		st.each { |word|
			VIM.command "syn keyword cppUserStructs #{word}"
		}

		cl = @keeper.classes
		cl.uniq!
		cl.each { |word|
			VIM.command "syn keyword cppUserClasses #{word}"
		}
	end

	def write_hi_vim
		VIM.command "hi cppUserTypedefs guifg=white"
		VIM.command "hi cppUserStructs guifg=white"
		VIM.command "hi cppUserClasses guifg=white"
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
def vim_main
	files = Dir["*.h"]
	out = $stdout

	recurse = VIM.evaluate('exists("g:syn_expand_recursive")').to_i
	if recurse == 1
		files = Dir["**/*.h"]
	end

	tofile = VIM.evaluate('exists("g:syn_expand_tofile")').to_i
	if tofile == 1 
		print tofile
		filename = VIM.evaluate('g:syn_expand_outputfile')
		out = File.open(filename, File::CREAT|File::TRUNC|File::WRONLY)
	end
	
	parser = FindKeywords.new
	writer = Highlighter.new out
	files.each { |arg|
		parser.parse arg
	}

	if tofile == 1
		writer.write_syn
		writer.write_hi
	else
		writer.write_syn_vim
		writer.write_hi_vim
	end
end
#}}}

vim_main

END
"}}}
endfunction

"vim:fdm=marker:ts=4:sw=4
