(:
 :  Script to dump database
 :
 :  Requires that the destination directory be externally bound
 :)
import module namespace m = "http://deepbills.dancingmammoth.com/modules/helpers";
declare variable $cwd as xs:string external;

declare function local:docs-with-meta() as document-node()* {
for $billname in m:billnames()
let $bill := m:open-bill($billname),
    $head := $bill[1],
    $body := $bill[2]/*
where $head/revision/@status="complete"
return document { element doc { $head, $body } }
};
for $doc in local:docs-with-meta()
let $bill := $doc/doc/docmeta/bill,
    $docname := concat($bill/@congress, $bill/@type, $bill/@number, $bill/@version)
return put($doc, concat('file://', $cwd,  $docname, '.xml'))
