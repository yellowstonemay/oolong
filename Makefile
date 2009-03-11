.PHONY: tags

all:

# Make tags for project
#
# add
#
# set tags=./tags,tags,/Users/Jim/dev/OolongEngine2SVN/oolongengine/Oolong\\\ Engine2/tags
# 
# to your ~/.vimrc to be able to use tags within MacVim where ever your session is ran from
tags:
	@echo "making tags for engine sourcecode (except Examples)"
	@ctags -R --c++-kinds=+p --fields=+iaS --extra=+q --exclude=Examples/* --exclude=DoxyDocs/* .

