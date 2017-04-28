xquery version "1.0";
(: --------------------------------------
   Case tracker pilote application

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Global variables or utility functions for the application

   Customize this file for your application

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace globals = "http://oppidoc.com/ns/xcm/globals";

(: Application name (rest), project folder name and application collection name :)
declare variable $globals:app-name := 'pilote';
declare variable $globals:app-folder := 'projects';
declare variable $globals:app-collection := 'ctracker';

(: Database paths :)
declare variable $globals:dico-uri := '/db/www/ctracker/config/dictionary.xml';
declare variable $globals:cache-uri := '/db/caches/ctracker/cache.xml';
declare variable $globals:global-info-uri := '/db/sites/ctracker/global-information';
declare variable $globals:settings-uri := '/db/www/ctracker/config/settings.xml';
declare variable $globals:log-file-uri := '/db/debug/login.xml';
declare variable $globals:application-uri := '/db/www/ctracker/config/application.xml';
declare variable $globals:templates-uri := '/db/sites/ctracker/global-information/templates.xml';
declare variable $globals:variables-uri := '/db/www/ctracker/config/variables.xml';
declare variable $globals:stats-formulars-uri := '/db/www/ctracker/formulars';
declare variable $globals:database-file-uri := '/db/www/ctracker/config/database.xml';

(: Application entities paths :)
declare variable $globals:persons-uri := '/db/sites/ctracker/persons';
declare variable $globals:enterprises-uri := '/db/sites/ctracker/enterprises/enterprises.xml';
declare variable $globals:cases-uri := '/db/sites/ctracker/cases';

(: MUST be aligned with xcm/lib/globals.xqm :)
declare variable $globals:xcm-name := 'xcm';
declare variable $globals:globals-uri := '/db/www/xcm/config/globals.xml';

declare function globals:app-name() as xs:string {
  $globals:app-name
};

declare function globals:app-folder() as xs:string {
  $globals:app-folder
};

declare function globals:app-collection() as xs:string {
  $globals:app-collection
};

(:~
 : Returns the selector from global information that serves as a reference for
 : a given selector enriched with meta-data.
 : @return The normative Selector element or the empty sequence
 :)
declare function globals:get-normative-selector-for( $name ) as element()? {
  fn:collection($globals:global-info-uri)//Description[@Role = 'normative']/Selector[@Name eq $name]
};

(: ******************************************************* :)
(:                                                         :)
(: Below this point paste content from xcm/lib/globals.xqm :)
(:                                                         :)
(: ******************************************************* :)

declare function globals:doc-available( $name ) {
  fn:doc-available(fn:doc($globals:globals-uri)//Global[Key eq $name]/Value)
};

declare function globals:collection( $name ) {
  fn:collection(fn:doc($globals:globals-uri)//Global[Key eq $name]/Value)
};

declare function globals:doc( $name ) {
  fn:doc(fn:doc($globals:globals-uri)//Global[Key eq $name]/Value)
};

