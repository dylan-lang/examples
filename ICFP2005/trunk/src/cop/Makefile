
cop.lib.du: cop.lid predicting-cop.dylan stupid-predicting-cop.dylan cop-exports.dylan dirty-cop.dylan ../shared/world.lib.du
	d2c -g -s -L../shared cop.lid

run:
	server --gui --robber "show-robber ../robber/robber-wrapper" --copE "show-cop ./cop-wrapper"

ruby:
	server --gui --robber "show-robber ../../ruby/Robber.rb NaiveRobber" --copE "show-cop ./cop-wrapper"

update:
	cd ../.. && svn update && cd -

M=""
commit:
	cd ../.. && svn commit -m "${M}" && cd -

clean:
	-rm -f *.o *.s *.a *.c *.mak *~ cop cop.lib.du
	-rm -rf .libs
