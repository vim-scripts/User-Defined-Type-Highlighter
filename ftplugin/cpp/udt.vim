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
"	in C++ header files.  It creates three groups, one each for typedefs, structs, and classes,
"	so if you want you can highlight those seperately.
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
"	I also ran it on /usr/include, it generated a syntax file that was 7000
"	lines long.  That file that it generated is located in
"	~/.vim/after/syntax/cpp/usr_include.vim.  BTW, when I ran this script on
"	/usr/include I was using a machine that had Mandrake on it.  So it may be
"	bloated, by way of association.  :)
"
"	Usage:
"	Read the help that comes with this plugin. ":he udt"
"
"	Options:
"	g:udt_recursive 
"		If g:recursive is not defined then it defaults to 0.
"		Valid setting are:	
"			0 = do not recurse directories looking for header files
"			1 = recurse directories
"	
"	g:udt_tofile
"		If this is defined then the output will be written to a file which can
"		be sourced at a later time.  This is good for working on projects with
"		several developers.	
"		If it is not defined then the syntax highlighting groups will be set
"		through vim commands.	
"		The value of this var is unimportant, just define it or don't.  Setting
"		it to 50, 4000, or "foobar" makes no difference.	
"
"	g:udt_outputfile
"		This contains the name of the file to which output will be written.
"		If you set the g:udt_tofile option, but do *not* set this option then
"		udt_highlight will default to writing the highlighting to "udt.vim".
"
"	Notes:
"	This comes with a command-line version.  It has similar options,
"	"udt.rb --help" for details.
"
"	This plugin was created tested and with my colorscheme, so you may or may not
"	like the colors that are the defaults.  One of the items on the todo list
"	is to add vars to determine the color of the highlighting.  But that will
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
"	* Add support for enums, enum members, and unions	
"	* Add support for dynamic loading from "#include" lines in header file,
"	  and associated header file for a .cpp file	

"Set up some defaults, but first make sure that they have not aleady been
"defined
if !exists("g:udt_recursive")
	let g:udt_recursive=0
endif

if !exists("g:udt_tofile")
endif

if !exists("g:udt_outputfile")
	let g:udt_outputfile="udt.vim"
end

"The attributes must be valid options to vim's ":hi" command.  See 
":he highlight-args (or for those with an aversion to typing ":he E416") 
"for details, and they must be seperated by whitepsace
if !exists("g:udt_typedef_atts")
	let g:udt_typedef_atts="guifg=white gui=bold"
end

if !exists("g:udt_struct_atts")
	let g:udt_struct_atts="guifg=white gui=bold"
end

if !exists("g:udt_class_atts")
	let g:udt_class_atts="guifg=white gui=bold"
end

"This is not implemented yet	{{{
"Note setting this option unsets g:udt_tofile.  This option will only
"work when not outputting the highlighting info to a file.
if exists("g:udt_dynamic_load")
	"Not implemented yet
end
"}}}

"This is the whole enchilada.
function! Generate_Highlighting()
"{{{
ruby << END

# Add paths to possible locations for se_core.rb.  This is more robust than
# the previous set up.  It will work 'out-of-box', without requiring the user
# to set env vars.  The prefered method is still to set the env var.
$: << "#{ENV['HOME']}/.vim" if FileTest.exist? "#{ENV['HOME']}/.vim/se_core.rb"
$: << ENV['SE_CORE'] if ENV['SE_CORE']


require 'se_core'

$typedef_group = 'cppUserTypedefs'
$struct_group = 'cppUserStructs'
$class_group = 'cppUserClasses'

#{{{
def vim_defined?(var_name)
	VIM.evaluate("exists('#{var_name}')").to_i == 1
end
#}}}
#{{{
def get_vim_var_val(var_name)
	VIM.evaluate("#{var_name}")
end
#}}}
#{{{
def vim_main

	if vim_defined?("g:udt_recursive") and get_vim_var_val("g:udt_recursive") == 1
		files = Dir["**/*.h"]
	else
		files = Dir["*.h"]
	end

	if vim_defined? "g:udt_tofile"
		filename = get_vim_var_val('g:udt_outputfile')
		f = File.open(filename, File::CREAT|File::TRUNC|File::WRONLY)
		out = f.method('write')
	else
		out = VIM.method('command')
	end
	
	parser = FindKeywords.new
	writer = Highlighter.new
	anything_to_write = true
	files.each { |arg|
		parser.parse arg
	}

	if anything_to_write
		atts = {
			"typedef" => get_vim_var_val("g:udt_typedef_atts"),
			"class" => get_vim_var_val("g:udt_class_atts"),
			"struct" => get_vim_var_val("g:udt_struct_atts")
		}
		writer.write_syn { |str|
			 out.call str
		}
		writer.write_hi(atts) { |str|
			 out.call str
		}
	else
		print 'Nothing to do'
	end
end
#}}}

vim_main

END
"}}}
endfunction

"vim:fdm=marker:ts=4:sw=4
