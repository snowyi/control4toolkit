# Introduction #

To be able to create working applications up against the control4 systems, we need to know how they work, and how they interface with each other. I, before even trying, doubt that control4 would help me out with hacking their communication protocols without buying their SDK etc, and I seriously doubt you would get it even if you bought it.

Soo, yeah. Let's just keep hacking until they make their stuff open source :)

# Journal #

When I first got my Home Theatre Controller, I found out that between Composer and the Director, stuff will go in XML-format. Something they obviously call "c4soap". Basicly a twoway xml soap-ish protocol. So, when you get information, or when you configure something with the composer, it will toss a chunk of xml to the director, and then it will reply if the data was ok, etc. :)

[Director2Composer c4soap-dump example](http://control4toolkit.googlecode.com/svn/trunk/drafts/director-information-dump.txt)