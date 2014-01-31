(:
 :  Script to dump database
 :
 :  Requires that the destination directory be externally bound
 :)
import module namespace m = "http://deepbills.dancingmammoth.com/modules/helpers";
declare variable $cwd as xs:string external;

declare function local:docs-with-meta($typefilter as xs:string) as document-node()* {
for $billname in m:billnames()
let $bill := m:open-bill($billname),
    $head := $bill[1],
    $body := $bill[2]/*
where $head/revision/@status="complete" and $head/bill/@type=$typefilter
return document { element doc { $head, $body } }
};

declare updating function local:dump-docs($typefilter as xs:string) {
	for $doc in local:docs-with-meta($typefilter)
	let $bill := $doc/doc/docmeta/bill,
	    $docname := concat($bill/@congress, $bill/@type, $bill/@number, $bill/@version)
	return put($doc, concat('file://', $cwd,  $docname, '.xml'))
};

local:dump-docs('hr'),
local:dump-docs('hrconres'),
local:dump-docs('hjres'),
local:dump-docs('hres'),
local:dump-docs('s'),
local:dump-docs('sconres'),
local:dump-docs('sjres'),
local:dump-docs('sres')
