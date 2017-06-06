xquery version "1.0";
(: --------------------------------------
   Case tracker pilote application

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Data template functions to use templates in templates.xml

   When you do not need to call custom functions in your data 
   templates you can call functions from XCM crud module.

   Otherwise copy paste the CRUD function you need from the
   crud module here so that you can import custom modules 
   (e.g. custom:gen-case-title)

   Customize this file for your application

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace template = "http://oppidoc.com/ns/xcm/template";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "globals.xqm";
import module namespace custom = "http://oppidoc.com/ns/xcm/custom" at "../app/custom.xqm";
import module namespace misc = "http://oppidoc.com/ns/xcm/misc" at "../../xcm/lib/util.xqm";
import module namespace xal = "http://oppidoc.com/ns/xcm/xal" at "../../xcm/lib/xal.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "../../xcm/lib/user.xqm";
import module namespace crud = "http://oppidoc.com/ns/xcm/crud" at "../../xcm/lib/crud.xqm";

declare function template:get-document( $name as xs:string, $case as element(), $lang as xs:string ) as element() {
  template:get-document($name, $case, (), $lang)
};

declare function template:get-document( $name as xs:string, $case as element(), $activity as element()?, $lang as xs:string ) as element() {
  let $src := globals:doc('templates-uri')/Templates/Template[@Mode eq 'read'][@Name eq $name]
  return
    if ($src) then
      misc:unreference(util:eval(string-join($src/text(), ''))) (: FIXME: $lang :)
    else
      oppidum:throw-error('CUSTOM', concat('Missing "', $name, '" template for read mode'))
};

declare function template:save-document( $name as xs:string, $case as element(), $form as element() ) as element() {
  crud:save-document($name, $case, (), $form)
};

declare function template:get-vanilla( $document as xs:string, $case as element(), $activity as element()?, $lang as xs:string ) as element() {
  let $src := fn:doc($globals:templates-uri)/Templates/Template[@Mode eq 'read'][@Name eq 'vanilla']
  return
    if ($src) then
      misc:unreference(util:eval(string-join($src/text(), ''))) (: FIXME: $lang :)
    else
      oppidum:throw-error('CUSTOM', concat('Missing vanilla template for read mode'))
};

declare function template:save-document(
  $name as xs:string, 
  $case as element(), 
  $activity as element(), 
  $form as element() 
  ) as element()
{
  crud:save-document($name, $case, $activity, $form)
};

(: ======================================================================
   TODO: check xal:apply-updates results
   ====================================================================== 
:)
declare function template:save-vanilla(
  $document as xs:string, 
  $case as element(), 
  $activity as element(), 
  $form as element() 
  ) as element()
{
  let $date := current-dateTime()
  let $uid := user:get-current-person-id() 
  let $src := fn:doc($globals:templates-uri)/Templates/Template[@Mode eq 'update'][@Name eq 'vanilla']
  return
    if ($src) then
      let $delta := misc:prune(util:eval(string-join($src/text(), '')))
      return (
        xal:apply-updates(if ($activity) then $activity else $case, $delta),
        oppidum:throw-message('ACTION-UPDATE-SUCCESS', ())
        )[last()]
    else
      oppidum:throw-error('CUSTOM', concat('Missing vanilla template for update mode'))
};
