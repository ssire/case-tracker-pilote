xquery version "1.0";
(: --------------------------------------
   Case tracker pilote application

   Creation: Stéphane Sire <s.sire@oppidoc.fr>

   CRUD controller for Case creation

   November 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)
import module namespace xdb = "http://exist-db.org/xquery/xmldb";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace compat = "http://oppidoc.com/oppidum/compatibility" at "../../../oppidum/lib/compat.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace misc = "http://oppidoc.com/ns/xcm/misc" at "../../../xcm/lib/util.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "../../../xcm/lib/user.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../../xcm/lib/access.xqm";
import module namespace ajax = "http://oppidoc.com/ns/xcm/ajax" at "../../../xcm/lib/ajax.xqm";
import module namespace database = "http://oppidoc.com/ns/xcm/database" at "../../../xcm/lib/database.xqm";
import module namespace enterprise = "http://oppidoc.com/ns/xcm/enterprise" at "../../../xcm/modules/enterprises/enterprise.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Returns a confirmation message in case the client enterprise is already
   client in another case. Return the empty sequence otherwise.
   This allows to implement a two steps protocol for case creation 
   to prevent redundant cases creation.
   FIXME: upper-case string for comparison ?
   ======================================================================
:)
declare function local:confirm-case-submission( $submitted as element(), $lang as xs:string ) as element()* {
  let $id :=  string($submitted/ClientEnterprise/EnterpriseRef)
  let $cas := for $c in fn:collection($globals:cases-uri)/Case[Information/ClientEnterprise/EnterpriseRef eq $id]
              return $c/Title/text()
  return
    if (count($cas) > 0) then
      oppidum:throw-message("CASE-CLIENT-CONFIRM", (enterprise:gen-enterprise-name($id, $lang), string-join($cas, ', ')))
    else
      ()
};

(: ======================================================================
   Validates Case submitted data. 
   Returns a list of errors to report or the empty sequence.
   This is to prevent mailicious submission that bypasses client-side validation 
   (e.g. hitting return after focusing a checkbox on Firefox !)
   FIXME: Check enterprise or person has not been deleted while case creation form and report error
   ======================================================================
:)
declare function local:validate-case-submission( $submitted as element(), $lang as xs:string ) as element()* {
  if (string($submitted/ClientEnterprise/EnterpriseRef) = '') then
    ajax:throw-error('WRONG-SUBMISSION', ()) 
  else
    ()
};

(: ======================================================================
   Returns a new Case from submitted case Information data
   See also gen-information-for-writing in information.xql
   FIXME: @EnterpriseId must be submitted with creation form (!)
   ======================================================================
:)
declare function local:gen-case-for-writing( $form as element(), $id as xs:string ) {
  let $uid := user:get-current-person-id()
  let $date :=  substring(string(current-dateTime()), 1, 10) 
  let $src := fn:doc($globals:templates-uri)/Templates/Template[@Mode eq 'create'][@Name eq 'case']
  return
    if ($src) then
      misc:prune(util:eval(string-join($src/text(), '')))  
    else
      oppidum:throw-error('CUSTOM', 'Missing "case" template for create mode')
 };

(: ======================================================================
   Create a new Case in database
   $base-url is used to generate redirection to the case URL once finished 
   Returns a success or error response compliant with AXEL-FORMS 'save' command protocol
   ======================================================================
:)
declare function local:create-case( $db-uri as xs:string, $submitted as element(), $base-url as xs:string, $lang as xs:string ) as element() {
  let $errors := local:validate-case-submission($submitted, $lang)
  return 
    if (empty($errors)) then
      (: ideally there should be a transaction here :)
      let $index := database:make-new-key-for($db-uri, 'case')
      let $data := local:gen-case-for-writing($submitted, $index)
      let $result := database:create-entity-for-key($db-uri, 'case', $data, $index)
      return 
        if (local-name($result) eq 'success') then
          ajax:report-success-redirect('ACTION-CREATE-SUCCESS', $index, concat($base-url, '/', $index))
        else
          $result
    else
      ajax:report-validation-errors($errors)
};

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $lang := string($cmd/@lang)
return
  if ($m eq 'POST') then (: create Case with submitted data with a 2 steps protocol :)
    let $submitted := oppidum:get-data()
    let $confirm := if (request:get-parameter('_confirmed', '0') = '0') then
                      local:confirm-case-submission($submitted, $lang)
                    else 
                      ()
    return
      if (empty($confirm)) then
        local:create-case($cmd/@db, $submitted, concat($cmd/@base-url,$cmd/@trail), $lang)
      else
        $confirm
  else  (: brings up a case creation formular :)
    <Page skin="formulars">
      <Window loc="case.title.create">Case creation</Window>
      <Content>
        <Formular Id="case">
          <Template>../templates/case?goal=create</Template>
          <Commands>
            <Save Target="case">
              <Label loc="action.save">Save</Label>
            </Save>
            <Cancel>
              <Action>../stage</Action>
              <Label loc="action.cancel">Cancel</Label>
            </Cancel>
            <Clear>
              <Label loc="action.clear">Reset</Label>
            </Clear>
          </Commands>
        </Formular>
      </Content>
    </Page>