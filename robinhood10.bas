type robinhood
	count as ulongint			'total items in the hash table
	tablemask as ulongint		'indexing mask for the table
	maxdis as ulongint			'current maximum displacement
	dishisto(any) as ulongint	'displacement histogram
	table(any) as ulongint		'key's, though zero is an empty slot 
	values(any) as ubyte		'value associated with a key, change the data type to suit
	' size should be a power of 2, eg. 2,4,8,16
	declare sub init(size as ulongint,histogramsize as ulong=128)
	' ordinary key
	declare function getvalue(x as ulongint,byref value as ubyte) as boolean
	declare function putvalue(x as ulongint,value as ubyte) as boolean
	declare function exists(x as ulongint) as boolean
	declare sub remove(x as ulongint)
	' pre-hashed key
	declare function getvalueh(hash as ulongint,byref value as ubyte) as boolean
	declare function putvalueh(hash as ulongint,value as ubyte) as boolean
	declare function existsh(hash as ulongint) as boolean
	declare function putvalueh(hash as ulongint) as boolean
	declare function updatevalueh(hash as ulongint,value as ubyte) as boolean
	declare function putvalueonceh(hash as ulongint,value as ubyte) as boolean
	declare sub removeh(hash as ulongint)
'other
	declare sub inchistogram(dis as ulong)
	declare sub dechistogram(dis as ulong)
	declare function mix(h as ulongint) as ulongint
end type
	
sub robinhood.init(size as ulongint,histogramsize as ulong=128)
	tablemask=size-1
	if (size and tablemask)<>0 then error(1)	'Size 2,4,8,16.....
	redim table(tablemask),values(tablemask),dishisto(histogramsize-1)
end sub

function robinhood.getvalue(x as ulongint,byref value as ubyte) as boolean
	return getvalueh(mix(x),value)
end function

function robinhood.putvalue(x as ulongint,value as ubyte) as boolean
	return putvalueh(mix(x),value)
end function

function robinhood.exists(x as ulongint) as boolean
	return existsh(mix(x))
end function
	
sub robinhood.remove(x as ulongint)
	removeh(mix(x))
end sub

function robinhood.getvalueh(hash as ulongint,byref value as ubyte) as boolean
	for i as ulongint =0 to maxdis
		var x=table((i+hash) and tablemask)
		if x=hash then
			value=values((i+hash) and tablemask)
			return true
		end if
		if x=0 then return false
	next
	return false
end function

function robinhood.existsh(hash as ulongint) as boolean
	for i as ulongint =0 to maxdis
		var x=table((i+hash) and tablemask)
		if x=hash then return true
		if x=0 then return false
	next
	return false
end function

function robinhood.updatevalueh(hash as ulongint,value as ubyte) as boolean
	for i as ulongint =0 to maxdis
		var x=table((i+hash) and tablemask)
		if x=hash then
			values((i+hash) and tablemask)=value
			return true
		end if
		if x=0 then return false
	next
	return false
end function

function robinhood.putvalueonceh(hash as ulongint,value as ubyte) as boolean
	if count>tablemask then return false	'there are no empty slots so return
	var idx=hash
	do
		idx and=tablemask
		var s=table(idx)							'item in the current slot
		var d1=((idx-hash) and tablemask) 			'carried item displacement
		if s=0 then									'an empty slot
			inchistogram(d1)						'update the displacement histogram
			table(idx)=hash							'insert
			values(idx)=value
			count+=1
			return true
		end if
		var d2=((idx-s) and tablemask)		'displacement of item in the slot
		if d2<d1 then						'then dump carried item (swap)
			dechistogram(d2)				'remove slot item displacement from the histogram
			inchistogram(d1)				'put the dumped item's displacement into the histogram
			table(idx)=hash					'dump hash
			var tvalue=values(idx)
			values(idx)=value				'dump value
			value=tvalue					'pick up value
			hash=s							'pick up hash
		end if
		idx+=1								'move on to the next slot
	loop
	return true
end function	
		
function robinhood.putvalueh(hash as ulongint,value as ubyte) as boolean
	if updatevalueh(hash,value) then return true
	return putvalueonceh(hash,value)
end function 

sub robinhood.removeh(hash as ulongint)
	for i as ulongint =0 to maxdis
		var idx=(i+hash) and tablemask
		var x=table(idx)
		if x=hash then
			dechistogram((idx-hash) and tablemask)
			do
				var idxplus=(idx+1) and tablemask
				var s=table(idxplus)
				if s=0 then exit do
				var d=(idxplus-s) and tablemask
				if d=0 then exit do
				dechistogram(d)
				inchistogram(d-1)
				table(idx)=s
				values(idx)=values(idxplus)
				idx=idxplus
			loop
			table(idx)=0
			count-=1
			return
		end if
		if x=0 then return
	next
end sub
	
sub robinhood.inchistogram(dis as ulong)
	if dis>ubound(dishisto) then redim preserve dishisto(dis+32)
	dishisto(dis)+=1
	if dis>maxdis then maxdis=dis
end sub

sub robinhood.dechistogram(dis as ulong)
	dishisto(dis)-=1
	if (dishisto(dis)=0) and (maxdis=dis) then
		while maxdis>0 
			maxdis-=1
			if dishisto(maxdis)>0 then return
		wend
	end if
end sub
' hash function
function robinhood.mix(h as ulongint) as ulongint
	h+=&h9E3779B97F4A7C15ULL
  	h = ( h xor ( h shr 30 ) ) * &hBF58476D1CE4E5B9ULL 
    h = ( h xor ( h shr 27 ) ) * &h94D049BB133111EBULL
    h xor= h shr 31
    if h=0 then h=1	'if the hash results in zero it has to be changed.
    return h			'zero is used as an empty slot marker to
end function			'save space and time
