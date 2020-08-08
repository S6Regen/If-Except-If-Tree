#include "robinhood10.bas"
#define DefaultChar 32

type bookchat
	table as robinhood
	declare sub init(tablesize as ulongint)
	declare sub learn(text as string,startposition as ulongint)
	declare function predict(text as string) as string
end type

sub bookchat.init(tablesize as ulongint)
	table.init(tablesize)
end sub
	
sub bookchat.learn(text as string,startposition as ulongint)
	for i as ulongint=startposition to len(text)  'first string index=1 in freebasic
		dim as ubyte result=DefaultChar
		dim as ulongint node=0		'start tree node
		for j as ulongint=i-1 to 1 step -1
			node=table.mix(node+asc(text,j)) ' node=hash of node and previous string character
			if not table.getvalueh(node,result) then 'searched back until no exceptions in hash table
			   dim as ubyte actual=asc(text,i) 'the letter you are trying to guess
			   if result<>actual then table.putvalueh(node,actual) 'if not correct create an except entry
			   exit for
			end if
		next 
	next
end sub

'predict next letter from complete text string
function bookchat.predict(text as string) as string
	dim as ubyte result=DefaultChar
	dim as ulongint node=0 'base tree node
	for i as ulongint=len(text) to 1 step -1
		node=table.mix(node+asc(text,i))
		if not table.getvalueh(node,result) then return chr(result)
	next 
	return chr(result)
end function



#define TreeSize 65536*256  'must be an integer power of 2 (2,4,8,16,32,64,......)
#define PredictLength 1000
ScreenRes 500,500,32
dim as bookchat bc
bc.init(TreeSize)

do
	cls
	print "Hash table count   " & bc.table.count & "/" & (bc.table.tablemask+1)
	print
	print "1/ File location of book to learn."
	print
	print "2/ Input start text"
	print
	Dim as integer key=getKey()
	select case key
		case asc("1")
			dim as string filename
			input "Book file: ",filename
			filename=lcase(trim(filename))
			if filename="" then exit select
			var ff=freefile()
			Open filename For Binary Access Read As #ff
			var slen=LOF(ff)
			if slen<20 then 
				print "File does not exist or is too small."
				print
				print "-> press a key <-"
				getkey
			else
				var text=space(slen)
				get #ff,,text
				bc.learn(text,10)
			end if
			Close #ff
		case asc("2")
		    dim as string startstring 
			input "Start string: ",startstring
			if startstring="" or bc.table.count=0 then 
			   exit select
			end if
			
			for i as ulong=1 to PredictLength
				startstring+=bc.predict(startstring)
			next
			print startstring
			print
			print "-> press a key <-"
			getkey		
		case 27,27647
		   system
	end select
loop

