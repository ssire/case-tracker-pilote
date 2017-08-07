Case tracker pilote
=======

    WARNING (August 2017)
    The Case tracker pilote is temporarily broken while we are refactoring 
    the XQuery Content Management Library.
    This warning will be removed when Case tracker pilote will ba available again.

The case tracker pilote application is a demonstration application built with the [XQuery Content Management Library](https://github.com/ssire/xquery-cm-lib) (XCM). It follows the principles described in this [software documentation manual](https://github.com/ssire/case-tracker-manual).

You can use the case tracker pilote as a scaffold to create all kind of content management applications with workflow management, semi-structured content editing, formular generation and e-mail output. The best way to start a new application is to clone the XQuery Content Management Library and to copy or clone the case tracker pilote project as explained in the installation notes below.

This demonstration maintains a database of **Person** and **Enterprise** entities. It also supports the creation of **Cases** and **Activities** and can track them with a workflow. Note that for demonstration purpose the cases and activities address a workflow to coordinate the allocation of coaches to companies and to follow up the coaching activities. If you are interested by the full coaching workflow please contact the main author.

To createa a full blown application you can configure a new workflow with its own document forms, replace the existing Person and Enterprise entities with other ones or create new ones. The document forms are stored in the *formulars* folder and they are managed by CRUD controllers stored in to the *modules* folder. The *Supergrid* formular generator available in the XCM library turns the formulars into web formulars. Do not forget to edit the *config/mapping.xml* file to expose the application entities as REST resources and to modify the *epilogue.xql* script to add them to the application menu.

This application is written in XQuery / XSLT / Javascript and the [Oppidum](https://github.com/ssire/oppidum) web application framework. This is a full stack XML application.

This application has been supported by the CoachCom2020 coordination and support action (H2020-635518; 09/2014-08/2016). Coachcom 2020 has been selected by the European Commission to develop a framework for the business innovation coaching offered to the beneficiaries of the Horizon 2020 SME Instrument.

Several case tracker applications based on this skeleton are used in production since 2013 for the eldest, in Switzerland and in Belgium.

The case tracker pilote application is developped and maintained by Stéphane Sire at Oppidoc.

Dependencies
----------

Runs inside [eXist-DB](http://exist-db.org/) (developed with [version 2.2](https://bintray.com/existdb/releases/exist))

Back-end made with [Oppidum](https://www.github.com/ssire/oppidum/) XQuery framework and the [XQuery Content Management Library](https://github.com/ssire/xquery-cm-lib).

Front-end made with [AXEL](http://ssire.github.io/axel/), [AXEL-FORMS](http://ssire.github.io/axel/) and [Bootstrap](http://twitter.github.io/bootstrap/) (all embedded inside the *resources* folder)

Compatiblity
----------

The current version runs inside eXist-DB installed on Linux or Mac OS X environments only. The Windows environment is not yet supported. This requires some adaptations to the Oppidum framework amongst which to generate file paths with the file separator for Windows.

License
-------

The case tracker pilote application and the case tracker library are released as free software, under the terms of the LGPL version 2.1. 

You are welcome to join our efforts to improve the code base at any time and to become part of the contributors by making your changes and improvements and sending *pull* requests.

Installation
------------

To run the case tracker pilote application you need to 

1. install [eXist-DB](https://bintray.com/existdb/releases/exist) (the application has been developed with eXist-DB 2.2), you can follow these [installation notes](https://github.com/ssire/oppidum/wiki/exist-db-installation-notes)
2. create a projects folder directly inside the webapp folder of your eXist-DB installation, you should call it *projects*
3. install Oppidum inside your *projects* folder, you can follow [How to install it ?](http://www.github.com/ssire/oppidum/) section of the Oppidum README file
4. clone the XQuery Content Management Library depot into your *projects* folder as a sibling of the *oppidum* folder, you MUST call it *xcm*
5. clone this depot into your *projects* folder as a sibling of the *oppidum* folder and *xcm*, you can clone it with any name, for instance *pilote* (shorter than *case-tracker-pilote*) then :
    * go to the `pilote/scripts` folder of this depot and run the *bootstrap.sh* command with the DB admin password as parameter
    * open the following URL to run the deployment script (you can use curl or wget command line too) : `http://localhost:PORT/exist/projects/pilote/admin/deploy?t=globals,config,data,forms,mesh,templates,stats,users,bootstrap,policies&pwd=[ADMIN PASSWORD]`
        * this will create a *demo* user (password *test*) that you can use to connect to the application as a system administrator, developer and account manager
        * this will also create a *coach* user (password *test*) that you can use to connect to the application as a coach

Note that in all the instructions above before running the *bootstrap.sh* script always check `EXIST-HOME/client.properties` points to the correct PORT before executing it in case you adjusted the default eXist-DB port (8080).

Assuming you installed eXist-DB into `/usr/local/pilote/lib`, here are the commands to execute to get it running :

    cd /usr/local/pilote/lib
    # ./bin/startup.sh & # starts eXist-DB; only if not yet running !
    mkdir -p webapp/projects
    cd webapp/projects
    git clone https://github.com/ssire/oppidum.git
    cd oppidum/scripts
    ./bootstrap.sh "admin PASSWORD"
    # you can open http://localhost:PORT/exist/projects/oppidum to check Oppidum installation
    cd ../..
    git clone https://github.com/ssire/xquery-cm-lib.git xcm
    git clone https://github.com/ssire/case-tracker-pilote.git pilote
    cd pilote/scripts
    ./bootstrap.sh "admin PASSWORD"
    curl -D - "http://localhost:PORT/exist/projects/pilote/admin/deploy?t=globals,config,data,forms,mesh,templates,stats,users,bootstrap,policies&pwd=[admin PASSWORD]"

Note that as an alternative to `curl -D -` you may use `wget -O-` or directly copy/paste the URL into your browser's window.

Once installed open [http://localhost:PORT/exist/projects/pilote]() and login with *demo* (password: *test*). 

From there you can create one or more users using the *Add a person* button in the *Community > Persons* area and you can manage user's roles in the *Users* tab in the *Admin* section since the *demo* user is a system administrator. You can also create cases since the *demo* user is also an account manager. Finally you can access the developer's menu since the *demo* user is also a developer.

Read header comments in `scripts/deploy.xql` to learn more about the different deployment targets.

## Database collection and REST project name

*NOTE: you can skip this section if you leave the defaults settings unchanged*

By default the case tracker pilote application creates two main collections `/db/sites/ctracker` and `/db/www/ctracker` to store respectively the end-user data and the application configuration data.

You may change the name of the main collection (i.e. *ctracker*) if you wish. For that purpose, before bootstrapping the application you must edit it in :

* `globals.xqm` (line 19) : declare variable $globals:app-collection := 'ctracker';
* `globals.xqm` : do a search and replace `/cctracker/` with your new collection name inside all the variable declarations of the form `$globals:`XXX`-uri`
* `controller.xql` (line 51) : let $mapping := fn:doc('/db/www/ctracker/config/mapping.xml')/site
* `bootstrap.sh` : edit the APPCOL variable
* `mapping.xml` : edit the `@db` and `@confbase` attributes on the `site` root element to fit your main collection name

By default the case tracker pilote application is configured to be cloned with a *pilote* project/folder name. This is the name used to obtain the application URLs in development mode (i.e. `/exist/projects/pilote`). You may change the name of the project/folder name if you wish. For that purpose, you need to edit it in :

* `globals.xqm` (line 17) : declare variable $globals:app-name := 'pilote';
* `bootstrap.sh` : should automatically detect it using shell commands and update the mapping and skin accordingly (see Trouble shooting section), but if that fail you may need to adapt this script

You may also eventually change the name of the parent project folder. For that purpose, you need to edit it in :

* `globals.xqm` (line 18) : declare variable $globals:app-folder := 'projects';

## Trouble shooting

#### Setting up an admin password

You need to setup a database admin password to run the *bootstrap.sh* scripts. In case your forgot it you can quickly use the java admin client in command line mode :

    $ cd /usr/local/pilote/lib/
    $ ./bin/client.sh -s
    Using locale: fr_FR.UTF-8
    eXist version 2.2 (master-5c5aadc), Copyright (C) 2001-2017 The eXist-db Project
    ...
    exist:/db>passwd admin
    password: ***
    re-enter password: ***
    exist:/db>quit

#### Running the application deployment script

It seems you should not be logged in to the case tracker pilote application while running the deployment script `/admin/deploy`. So in case your try to run it multiple times, if you get an error, logout and run it again. 

The *users*, *bootstrap* and *policies* targets are required only the first time, to create the initial `persons.xml` and `enterprises.xml` resources, and to setup collection permissions. DO NOT re-run the *bootstrap* target if you have created more users or enterprises because they would be lost.

#### Correct mapping and skin configuration

You can always check the root element of `/db/www/cctracker/config/mapping.xml` resource after installation:

* *db* attribute should point to your main data collection (/db/sites/ctracker)
* *confbase* attribute should point to your main configuration data collection (/db/www/ctracker)
* *key* should contain your REST project name (pilote)

and check the root element of `/db/www/cctracker/config/skin.xml` resource after installation:

* *key* should contain your REST project name (pilote)

this is particularly true in case you changed the defaults, although running *bootstrap.sh* should have updated them. 

Coding conventions
---------------------

* _soft tabs_ (2 spaces per tab)
* no space at end of line (ex. with sed : `sed -E 's/[ ]+$//g'`)
