xquery version "1.0";
(:~ 
 : Case tracker pilote application
 :
 : This module provides the helper functions that depend on the application
 : specific data model, such as :
 : <ul>
 : <li> label generation for different data types (display)</li>
 : <li> drop down list generation to include in formulars (form)</li>
 : <li> miscellanous utilities (misc)</li>
 : </ul>
 : 
 : You most probably need to update that module to reflect your data model.
 : 
 : NOTE: actually eXist-DB does not support importing several modules
 : under the same prefix. Once this is supported this module could be 
 : splitted into corresponding modules (display, form, access, misc)
 : to be merged through import with their generic module counterpart.
 :
 : January 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
 :
 : @author Stéphane Sire
 :)
module namespace custom = "http://oppidoc.com/ns/xcm/custom";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../lib/globals.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../xcm/lib/display.xqm";
import module namespace cache = "http://oppidoc.com/ns/xcm/cache" at "../../xcm/lib/cache.xqm";
import module namespace form = "http://oppidoc.com/ns/xcm/form" at "../../xcm/lib/form.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "../../xcm/lib/user.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../xcm/lib/access.xqm";
import module namespace enterprise = "http://oppidoc.com/ns/xcm/enterprise" at "../../xcm/modules/enterprises/enterprise.xqm";

declare namespace xt = "http://ns.inria.org/xtiger";

(: ======================================================================
   Generates selector for creation years
   NOTE: for stats
   ======================================================================
:)
declare function custom:gen-creation-year-selector ( ) as element() {
  let $years := 
    for $y in distinct-values(fn:doc($globals:enterprises-uri)//CreationYear)
    where matches($y, "^\d{4}$")
    order by $y descending
    return $y
  return
    <xt:use types="choice" values="{ string-join($years, ' ') }" param="select2_dropdownAutoWidth=on;select2_width=off;class=year a-control;filter=optional select2;multiple=no"/>
};

(: ======================================================================
   Generates XTiger XML 'choice' element for selecting a  Case Impact (Vecteur d'innovation)
   NOTE: for stats
   TODO: 
   - caching
   - use Selector / Group generic structure with a gen-selector-for( $name, $group, $lang, $params) generic function
   ======================================================================
:)
declare function custom:gen-challenges-selector-for  ( $root as xs:string, $lang as xs:string, $params as xs:string ) as element() {
  let $pairs :=
        for $p in fn:collection($globals:global-info-uri)//Description[@Lang = $lang]/CaseImpact/Sections/Section[SectionRoot eq $root]/SubSections/SubSection
        let $n := $p/SubSectionName
        return
           <Name id="{$p/Id/text()}">{(replace($n,' ','\\ '))}</Name>
  return
   let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
   let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
   return
     <xt:use types="choice" values="{$ids}" i18n="{$names}" param="{form:setup-select2($params)}"/>
};

declare function custom:gen-short-case-title( $case as element(), $lang as xs:string ) as xs:string {
  let $ctx := $case/NeedsAnalysis/Context/InitialContextRef
  return
    if ($ctx) then
      concat(display:gen-name-for("InitialContexts", $ctx, $lang), ' - ', substring($case/CreationDate, 1, 4))
    else
      concat('... - ', substring($case/CreationDate, 1, 4))
};

declare function custom:gen-case-title( $case as element(), $lang as xs:string ) as xs:string {
  concat(
    enterprise:gen-enterprise-name($case/Information/ClientEnterprise/EnterpriseRef, 'en'),
    ' - ',
    custom:gen-short-case-title($case, $lang)
    )
};

declare function custom:gen-short-activity-title( $case as element(), $activity as element(), $lang as xs:string ) as xs:string {
  let $service := $activity/Assignment/ServiceRef
  return
    if ($service) then
      concat(display:gen-name-for("Services", $service, $lang), ' - ', substring($activity/CreationDate, 1, 4))
    else
      concat('service pending - ', substring($activity/CreationDate, 1, 4))
};

declare function custom:gen-activity-title( $case as element(), $activity as element(), $lang as xs:string ) as xs:string {
  concat(
    enterprise:gen-enterprise-name($case/Information/ClientEnterprise/EnterpriseRef, 'en'),
    ' - ',
    custom:gen-short-activity-title($case, $activity, $lang)
    )
};

(: ======================================================================
   "All in one" utility function
   Checks case exists and checks user has rights to execute the goal action 
   with the given method on the given root document or has access to 
   the whole case if the root is undefined
   Either throws an error (and returns it) or returns the empty sequence
   ======================================================================
:)
declare function custom:pre-check-case(
  $case as element()?,
  $method as xs:string,
  $goal as xs:string?,
  $root as xs:string? ) as element()*
{
  if (empty($case)) then
    oppidum:throw-error('CASE-NOT-FOUND', ())
  else if (not(access:check-user-can('open', 'Case', $case))) then
    oppidum:throw-error("CASE-FORBIDDEN", custom:gen-case-title($case, 'en'))
  else if ($root) then 
    (: access to a specific case document :)
    if (access:check-user-can(if ($method eq 'GET') then 'read' else 'update', $root, $case, ())) then
      ()
    else
      oppidum:throw-error('FORBIDDEN', ())
  else if ($method eq 'GET') then
    (: access to case workflow view :)
    ()
  else
    oppidum:throw-error("URI-NOT-FOUND", ())
};

(: ======================================================================
   "All in one" utility function
   Same as custom:pre-check-case but at the activity level
   ======================================================================
:)
declare function custom:pre-check-activity(
  $case as element()?,
  $activity as element()?,
  $method as xs:string,
  $goal as xs:string?,
  $root as xs:string? ) as element()*
{
  if (empty($case)) then
    oppidum:throw-error('CASE-NOT-FOUND', ())
  else if (empty($activity)) then 
    oppidum:throw-error('ACTIVITY-NOT-FOUND', ())
  else if (not(access:check-user-can('open', 'Case', $case))) then
    oppidum:throw-error("CASE-FORBIDDEN", $case/Title/text())
  else if ($root) then (: access to specific activity document :)
    let $action := if ($method eq 'GET') then 'read' else if ($goal eq 'delete') then $goal else 'update'
    let $control := globals:doc('application-uri')/Application/Security/Documents/Document[@Root = $root]
    return
      if (access:assert-user-role-for($action, $control, $case, $activity)) then
        if (access:assert-workflow-state($action, 'Activity', $control, string($activity/StatusHistory/CurrentStatusRef))) then
          ()
        else
          oppidum:throw-error('STATUS-DONT-ALLOW', ())
      else
        oppidum:throw-error('FORBIDDEN', ())

  else if ($method eq 'GET') then (: access to activity workflow view :)
    ()
  else
    oppidum:throw-error("URI-NOT-FOUND", ())
};
