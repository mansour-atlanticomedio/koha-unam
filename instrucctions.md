== Before you begin ==

These instructions assume you are starting from scratch, on a fresh '''Debian or Ubuntu''' server, with none of the prerequisites already installed.

Following these instructions will give you a basic, working Koha installation for you to test and experiment with.

However, the instructions are not designed to give you a production system that you can make available on the internet to your library staff and patrons.

Setting up a production environment requires many things, such as:

*security (hardening servers, security certificates, firewalls, application firewalls, and  so on)
*setting up a mail server (or using a third-party)
*backing up your data (for the both the database and server)
* having support to deal with issues
* managing updates, including operating system updates and security updates
*... and much more beyond the scope of these instructions

== System requirements and recommendations==
Koha is web-based server software, not a desktop application, and uses a wide range of software to run, such as:

*Perl
*Perl packages from CPAN
*A database server - MariaDB or MySQL
*A web server - Apache
*Caching - Plack
*A search engine - Zebra or Elasticsearch/OpenSearch.

See the [[System_requirements_and_recommendations|system requirements and recommendations page]] for information about which operating system versions are tested and known to work.

Hardware and memory requirements:

*The memory requirements to run Koha are significant (2 GB minimum, 4 GB+ recommended)
*You '''must''' ensure that the server has adequate free memory available to run Koha before you begin
* These instructions will result in an instance of Koha that will consume between 750MB - 1GB of memory '''at idle'''
*If you are installing the database server on the same server as Koha, it is probably going to need another 350MB - 500MB of RAM
*If you are installing Elasticsearch instead of using Zebra as a your search engine, it will need another ~500 MB for an average-size installation (by default Elasticsearch reserves half of the server's physical memory, you may want to check its actual usage and then limit the amount it reserves, so that it doesn't starve other services off memory)
*The database and web server can be tuned to reduce memory consumption, but those optimizations and their consequences are outside of the scope of these instructions
*Having swap enabled will help absorb any spikes in memory needs and avoid processes crashing due to out-of-memory (4 GB minimum swap file/partition)

==Conventions==

Run the commands that are in a box and start with <code>$</code> at the command line prompt for your server (don't include the '$'): 

 $ ''a_command''

Run the commands that are in a box and start with <code>#</code> at the command line prompt for your server as ''root'' (don't include the '#'): 

 # ''a_command''

{{Ambox|small=left|style=width: auto; margin-right: 0px;|textstyle=width: auto;|smalltext=The commands prefixed with <code>#</code> should be run from a ''root shell'', which can be accessed with <code>sudo -i</code> or <code>su -</code>.<br>Running <code>sudo ''command''</code> from an unprivileged shell instead of <code>''command''</code> from a root shell will also work in most cases.}}

==Installing the operating system==
Debian based operating systems are recommended. This includes Debian and Ubuntu. 

Normally, install a minimal server version of the operating system, and then use the Koha packages. 

==Using the Koha packages==

Koha's Debian packages are the preferred, easiest, and '''recommended''' way to install Koha. 

Our packages are tested on Debian and Ubuntu Long Term Support (LTS) releases. 

===Setting up the keys for the Koha package sources ===
Keys help ensure the packages you are using haven't been tampered with.
<pre>
# apt update
# apt install apt-transport-https ca-certificates curl sudo
# mkdir -p --mode=0755 /etc/apt/keyrings
# curl -fsSL https://debian.koha-community.org/koha/gpg.asc -o /etc/apt/keyrings/koha.asc
</pre>

===Setting up the package sources===
Choose which package source to follow - this determines what packages are updated when you run updates:

*a '''version number''', or
*a '''code name''' for a release

{| class="wikitable"
|+Choosing which package sources to follow
!Option
!Description
!Example of what happens when you run updates
|-
|'''Version number''' 
'''(recommended)''', 

such as 25.05

|You stay on '''this version''' and only receive maintenance release updates.
Upgrading to a later major version, such as 25.11, requires changing the package sources.
|
*The package source you follow is <code>25.05</code>
* You are on <code>25.05.05</code>
*When you run updates, you are updated to the latest  maintenance release available, for example <code>25.05.06</code>
|-
|'''Code name''', 
such as stable

or oldstable
|You are upgraded by default to the next '''major release for that code name''' every 
six months (in May and November).

Between major releases, you receive monthly maintenance releases.

|
*The package source you follow is <code>stable</code>, and this is currently 25.05.05
*Koha <code>25.11.00</code> is released - this is Koha's major six-monthly release,   and becomes the new <code>stable</code>
*When you run updates, you are updated to the new major release of Koha, going   from <code>25.05.05 to 25.11.00</code>
|}

====Following a version number (recommended)====

When you follow a specific Koha version number, you stay on this version of Koha until the package sources are changed. 

This is '''recommended''' for production environments, so that you don't 'accidentally' upgrade to a new major release.

When you run updates, you only upgrade to the latest maintenance release for the version chosen.

The currently supported Koha versions and their code names are:

*'''25.11''' (stable) - the current stable release
*'''25.05''' (oldstable) follows one release behind the current stable release
*'''24.11''' '''(LTS release)''' (oldoldstable) follows one release behind the current stable release
*'''22.11''' (LTS release) (oldoldoldstable(?)) is the previous long-term support release, maintained for approximately 3 1/2 years to ?

To update your package source list to use the '''25.11''' release:
```
# tee /etc/apt/sources.list.d/koha.sources <<EOF
 Types: deb
 URIs: <nowiki>https://debian.koha-community.org/koha/</nowiki>
 Suites: 25.11
 Components: main
 Signed-By: /etc/apt/keyrings/koha.asc 
 EOF
```
 
To update your package source list to use the '''25.05''' release:
```
# tee /etc/apt/sources.list.d/koha.sources <<EOF
Types: deb
URIs: https://debian.koha-community.org/koha/
Suites: 25.05
Components: main
Signed-By: /etc/apt/keyrings/koha.asc 
EOF
```

Note: if you previously used the old APT sources list format, remove <code>/etc/apt/sources.list.d/koha.list</code> file.

To update the packages list:
<pre>
# apt update
</pre>

==== Following a code name (not recommended)====

When you follow a code name for a release, you are '''automatically''' upgraded to the latest major Koha release available for that code name.

For example, when the 25.11 release becomes available and you run updates: 

*if you follow the current stable release, you would be upgraded from Koha 25.05 to 25.11 when the 25.11 release becomes available
*if you follow oldstable, you would be upgraded from Koha 24.11 to 25.05.

Following a code name for a release is '''NOT''' recommended for a production environment, unless you like "living on the edge". 

Major releases contain new features and many enhancements, and sometimes unexpected issues can occur–despite the release team's best efforts to create a stable release.

It is highly recommended that libraries test before upgrading between major versions. See [[Koha Versioning|Koha versioning and the recommendations section]].

The current code names and their versions are:

*'''stable''' (currently 25.11) is the latest stable release
*'''oldstable''' (currently 25.05) follows one release behind the current stable release
*'''oldoldstable''' (currently 24.11 and the next LTS release) follows two releases behind the current stable release, and thw next long-term support release
*'''oldoldoldstable''' (currently 22.11 and an LTS release) is the long-term support release, maintained for approximately 3 1/2 years

To update the package source list to use the '''stable''' release:
```
# tee /etc/apt/sources.list.d/koha.sources <<EOF
Types: deb
URIs: https://debian.koha-community.org/koha/
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/koha.asc 
EOF
```

To update the package source list to use the '''oldstable''' release:
```
# tee /etc/apt/sources.list.d/koha.sources <<EOF
Types: deb
URIs: https://debian.koha-community.org/koha/
Suites: oldstable
Components: main
Signed-By: /etc/apt/keyrings/koha.asc 
EOF
```


To update the packages: 
<pre>
# apt update
</pre>

==Installing the Koha packages==
 # apt install koha-common

==Install the database==

If you are using a database on another server, this step is not required.

You can use '''MariaDB''' (recommended) or '''MySQL''' as the database server.

To use MariaDB:

 # apt install mariadb-server

To use MySQL:

 # apt install mysql-server 

====MySQL vs MariaDB====

MariaDB is recommended as it is the default mysql server in Debian.

==Configure the default Apache settings for Koha instances ==

Edit the file <tt>/etc/koha/koha-sites.conf</tt> and adjust it to suit your requirements.

====Using a domain name====
Set the '''DOMAIN''' to the domain name that you will access Koha from.

Also set '''INTRASUFFIX'''.

Using a domain name requires valid DNS entries in your network - see [[how to set up a domain name for Koha]].

==== Using a domain name or IP address====
Some useful information on how to set up your koha-sites.conf can also be found in [[Koha_on_ubuntu_-_packages#Appendix_A:_Named-based_vs._IP-based_installations|Appendix A: Named-based vs. IP-based installations]].

====MARC21 or UNIMARC?====
If your catalog is using UNIMARC, change '''ZEBRA_MARC_FORMAT'''. You may also adapt '''ZEBRA_LANGUAGE'''.

==Set up Apache ==

 # a2enmod rewrite cgi headers proxy_http
 # systemctl restart apache2

If you are configuring Koha for access by IP address rather than by domain name, edit <tt>/etc/apache2/ports.conf</tt> and make sure the following lines are present:

 Listen 80
 Listen <staff interface port number>

You only need the second Listen entry if you have chosen to make the staff interface accessible on a different port.

==Create a Koha instance==

==== Using a database located on the same server as Koha====
Replace ''libraryname'' with the name of your library. 

 # koha-create --create-db libraryname
 # koha-plack --enable libraryname
 # koha-plack --start libraryname
 # systemctl restart apache2


For more options, see [[Commands provided by the Debian packages#koha-create]].

'''Important:''' Check the available options for <tt>koha-create</tt> carefully. If you use UNIMARC, you'll need to use the <code>--marcflavor</code> option to set up your instance correctly.

==== TO BE TESTED AND UPDATED - Using a database on another server====
#Remove <tt>/etc/mysql/koha-common.cnf</tt>

### Create a new "option file" in its place with the same file name containing the client connection information for the server (the same syntax you'll find in a <tt>my.cnf</tt> file).
#* You will need to specify the host, user, and password within a [client] option group.
#*Koha commands will automatically use the /etc/mysql/koha-common.cnf via the --defaults-extra-file option for the MySQL CLI client
#Read the man pages for <tt>koha-create</tt>, paying attention to the information on <tt>--request-db</tt> and <tt>--populate-db</tt>.
#Using <tt>--request-db</tt> will disable koha instance, so to enable the instance after using <tt>--populate-db</tt>, perform command <tt>koha-enable ''libraryname''</tt>.

==Access the web interface==

You will need to have your DNS set up for this. 

The default host names, where ''libraryname'' is the name used with koha-create, are:

*<tt>''libraryname''.myDNSname.org</tt> for the public interface
*<tt>''libraryname''-intra.myDNSname.org</tt> for the staff interface

In the default configuration it is impossible to access the web interfaces directly by the server's IP address, so you will have to change the above hostnames by editing <tt>/etc/apache2/sites-enabled/''libraryname''.conf</tt> and reloading Apache.

Alternatively, you may temporarily modify <tt>the hosts</tt> file on your client machine to temporarily point these hostnames to the server's IP address.

Open a web browser, and point it to your staff interface, by going to <tt>http://''libraryname''-intra.myDNSname.org</tt>, or whatever you manually configured. 

When you see the login for the Koha installer, the username and password are in the ''koha-conf.xml'' file for the instance.

You can view the password with:

 # koha-passwd libraryname

Outputs:
<pre>
Username for temp: koha_libraryname
Password for temp: randompasswordtext
Press enter to clear the screen...
</pre>

Or you can access them for shell scripting directly from the generated config file:

 ### KOHA_USER=$(xmlstarlet sel -t -v '/yazgfs/config/user' /etc/koha/sites/libraryname/koha-conf.xml)
 ### KOHA_PASS=$(xmlstarlet sel -t -v '/yazgfs/config/pass' /etc/koha/sites/libraryname/koha-conf.xml)

Note that these credentials are only used for the web installer, which will prompt you at the end to provide new actual username and password for the first administrative user.

====If you encounter timeout errors====

Some steps taken by the web-based installer to set up database tables may take some time to complete, and may generate timeout errors.

If you receive a "Gateway Timeout" error in the web browser, try editing the file <tt>/etc/apache2/apache2.conf</tt> to increase apache's <tt>''Timeout''</tt> setting.

Avoid using extra reverse proxies in front of the server during the installation.

==Additional configuration==

===Email===

To send notices, your server needs to be configured to send email. This requires skills in setting up Mail Transport Agents, such as postfix or Exim4, or access to a mail server. THIS IS BEYOND THE SCOPE OF THESE INSTRUCTIONS. 

By default, sending email from Koha is turned off - this is so everything can be set up before risking sending unwanted notices to people. 

To turn email on: 

 # koha-email-enable libraryname
Important note: once a server is configured to send email, and email is enabled for your Koha instance, it will only send email when the cronjob <code>misc/cronjobs/process_message_queue.pl</code> is run.

===Translations===

To see all the languages available to install:

 # koha-translate --list --available
   am-Ethi
   ar-Arab
   as-IN
   ...

Use the language codes to install translations, for example:

 # koha-translate --install am-Ethi ar-Arab as-IN

The installed Koha languages are automatically updated when updates are run, as the language packages get updated by the packaging system.

You should also have the relevant locales installed on the base Debian system to avoid running into some issues:

#Edit <tt>/etc/locale.gen</tt>
#Uncomment the UTF-8 entries for languages required
#Run <tt>locale-gen</tt> command.

If you don't do the above, you will likely experience warnings in logs, with practical effects like the page titles (<nowiki><title></nowiki>) not being translated. Many of the Debian slim/cloud default installs will only have "C" locale enabled by default, with not even the "en_US" one being enabled.

===Server administration===

====Commands provided by the Debian packages====

There is a list of [[commands provided by the Debian packages]]. All commands begin with ''koha-'', and have man pages installed. To access the man page for a command: 

 $ man koha-create

====Services====

Koha installs a service in <tt>/etc/init.d/koha-common</tt>

This ensures that the configured and enabled Koha services, such as Plack daemon, Zebra daemon, Z39.50 responder daemon, SIP daemon are running.

A systemd unit <tt>koha-common</tt> is also installed. You can use the <tt>start</tt>, <tt>stop</tt>, and <tt>restart</tt> commands to control these.

===Search - non-latin languages===

To get searching with non-latin languages (such as Russian, Chinese and Arabic) working correctly in Koha you need to [[ICU chains configuration|set up and configure ICU]].

===Search - using Elasticsearch===

If you want to use Elasticsearch instead of Zebra, follow these steps:

Install the Koha dependencies:
 # apt install koha-elasticsearch
Add the Elasticsearch sources: <pre>
# curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch -o /etc/apt/keyrings/elasticsearch.asc
# tee /etc/apt/sources.list.d/elasticsearch.sources <<EOF
Types: deb
URIs: https://artifacts.elastic.co/packages/8.x/apt
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/elasticsearch.asc
EOF
</pre>Install the Elasticsearch server:

 # apt update
 # apt install elasticsearch

Start up the server:

 # systemctl daemon-reload
 # systemctl enable --now elasticsearch.service

Install the analysis-icu plugin:

 # /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-icu

Note that you need to manually remove and re-install the ''analysis-icu'' plugin after every Elasticsearch package update (using the ''elasticsearch-plugin'' tool above), which is a hassle.

Since Elasticsearch 8.0, security features are enabled and unauthenticated users cannot connect to the service. Either read the password for <code>elastic</code> user from the output of <code>apt install</code> command above, or reset it with:

 # /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic

Afterwards, edit <code>/etc/koha/sites/libraryname/koha-conf.xml</code> and find the section <code><nowiki><elasticsearch></nowiki></code>. Inside of it you should have the below snippet if you installed Koha recently (otherwise, add it):
<pre>
     <!-- If you are using authentication, you will also need to use HTTPS. Uncomment and tweak the following for your ES setup. -->
     <!-- NOTE: instead of userinfo, you can alternatively provide the username and password in URL in the server element -->
     <!--
     <userinfo>elastic:CHANGEME</userinfo>
     <use_https>1</use_https>
     -->
</pre>

Change <code>CHANGEME</code> to the password of the <code>elastic</code> user that you have generated above and remove the <code><nowiki><!--</nowiki></code> and <code><nowiki>--></nowiki></code> around the values.

Then, below <code><nowiki><use_https>1</use_https></nowiki></code>, add this (since the default setup is using a self-signed certificate):
<pre>
    <handle_args><verify_SSL>0</verify_SSL></handle_args>
</pre>

NOTE: On older Koha versions you may need to disable the security features in order to allow the HTTP API port to work. If you do that, ensure that you configure it to NOT be accessible from the open internet (for example with a firewall like ufw), only from within localhost. If the command below fails, it's not set up properly and won't work in Koha. Disabling security is not recommended if it can be avoided!

Restart the services to have them pick up the changes:

 # systemctl restart elasticsearch.service
 # systemctl restart koha-common.service

Wait a few seconds, then check if it is running correctly.

With security enabled, run:
 $ curl -k -u 'elastic:CHANGEME' https://localhost:9200

With security disabled, run:
 $ curl localhost:9200

Expected output similar to:

<pre>
{
  "name" : "koha",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "cTXuxxIPTd2KrWgyRCPAxw",
  "version" : {
    "number" : "8.15.0",
    "build_flavor" : "default",
    "build_type" : "deb",
    "build_hash" : "1a77947f34deddb41af25e6f0ddb8e830159c179",
    "build_date" : "2024-08-05T10:05:34.233336849Z",
    "build_snapshot" : false,
    "lucene_version" : "9.11.1",
    "minimum_wire_compatibility_version" : "7.17.0",
    "minimum_index_compatibility_version" : "7.0.0"
  },
  "tagline" : "You Know, for Search"
}
</pre>

Switch the system preferences ''SearchEngine'' to 'Elasticsearch' then index your records:

 # koha-elasticsearch --rebuild -d libraryname

To make sure it's working, search in your catalogue for <code>*</code> (asterisk symbol). If you get any results, assuming non-empty catalog, it's working (in Zebra the asterisk would not work).

===Search - using OpenSearch===
To be added

=== Anacron - Zebra search engine issues===

If you are using Anacron, it may cause Zebra search engine server to go down occasionally (see https://lists.katipo.co.nz/pipermail/koha/2016-September/046167.html).

To avoid that:

1. Edit ''/etc/cron.d/anacron'' and add a ''#'' to turn off the line starting  with 30 7 * * *  ....anacron...

2. Rename "anacron"

 # mv /usr/sbin/anacron /usr/sbin/anacron-temporarily-renamed

==Upgrading Koha==

'''IMPORTANT''': 

*Before running any updates and upgrades, make sure you have backups so you can restore your environment if anything goes wrong.
*The best practice with any technology systems is to to test upgrades in a testing environment, so that you can identify any issues.

Before upgrading Koha, update your system's package information:

 # apt update

To confirm which version of Koha is installed, and which version will be upgraded to, run:

 $ apt-cache policy koha-common | grep -E 'Installed|Candidate'
 Installed: 21.05.01-1
 Candidate: 21.05.09-1

If you installed Koha as described above (by setting it to follow specific version releases as recommended), an upgrade should be as easy as this:

 # apt upgrade

This will upgrade to the latest minor version, for example, from 19.11.10 to 19.11.11. (It will also upgrade all the other software on your server that needs an upgrade.)

The upgrade will print a list of software to be updated--please read this list before proceeding with the upgrade.

If you use Elasticsearch and it's being updated, remember to reinstall the ''analysis-icu'' plugin as outlined in Elasticsearch installation section.

===Upgrading Koha to a major version===
'''If you want to upgrade to a newer major version (for example, from 19.11.x to 20.05.x) you may need to adjust the file <code>/etc/apt/sources.list.d/koha.sources</code> (formerly <code>koha.list</code>) before you do "apt update".''' 

See "Choosing what Koha release to follow - a version number or a code name" above for an idea of what you need to do.

Note: if you previously used the old APT sources list format, remove <code>/etc/apt/sources.list.d/koha.list</code> file.

Then, after adjusting <code>/etc/apt/sources.list.d/koha.sources</code> you should be able to upgrade with the same commands:

 # apt update
 $ apt-cache policy koha-common | grep -E 'Installed|Candidate'
 Installed: 19.05.14-1
 Candidate: 21.05.04-1

If the 'Candidate' version looks correct, then:
 # apt upgrade

Sometimes this will not upgrade Koha, because it is "held back" (this happens when the upgrade means you have to install new packages on the server, for example, new Perl modules). In that case you have to try again with this command:

 # apt dist-upgrade

Remember to always scan the output of these commands for any error messages related to the upgrading of the Koha database.<br><br>'''Confirm the 'koha-common' package has been installed successfully'''
 $ dpkg -s koha-common | grep Status
 Status: install ok installed

==Advanced information - Koha packaging information==

===Release policy===

Maintenance releases for supported versions of Koha are released around the 20th of every month.

===How <tt>koha-create</tt> configures your system===

When you create an instance with <tt>koha-create</tt>, a few things happen. For the sake of example, this assumes that the instance you created is called '''library'''. 

*A system user is created, called <tt>library-koha</tt>. All things to do with this instance will be run as this user.
*(If you have a local MySQL) a new MySQL user is created called <tt>koha_library</tt>
*(If you have a local MySQL) a new MySQL database is created called <tt>koha_library</tt>
*<tt>/var/lib/koha/library</tt> is created and populated with a default directory structure.
*The Koha sites directory (<tt>/etc/koha/sites/library</tt>) is created and populated. In particular, a <tt>koha-conf.xml</tt> is generated and put there with the passwords that were randomly generated for the database and zebra.
*An apache configuration file is put in <tt>/etc/apache2/sites-available/library.conf</tt>. Apache is restarted to make the change take effect.
*A Zebra daemon for this instance is started, running as the <tt>library-koha</tt> system user.

===Packaging releases===

There is a bit of a mind-dump of information on [[Building Debian Packages]] for release. If you want to maintain your own packages, also have a look at [[Building Debian Packages - The Easy Way]].

===Other things ===

*[[PackagesIndexDaemon|Using the Index Daemon with the packages]]
*[[Newbie guide]] - to begin the working configuration
*[[Building Debian Dependencies]] - what to do if we need to add a new dependency that's not in Debian

==Troubleshooting - warnings and errors==

====Failed to enable unit: Unit /run/systemd/generator.late/koha-common.service====
You can safely ignore the following warning when installing or upgrading koha, (fixed in bug [https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=33371 33371])

 Failed to enable unit: Unit /run/systemd/generator.late/koha-common.service is transient or generated.

====Errors were encountered while processing: libapache2-mpm-itk====

If you see this: 

 Errors were encountered while processing:
 libapache2-mpm-itk
 apache2-mpm-itk
 koha-common

Then do this: 

 # a2dismod mpm_event 
 # apt-get install -f

====Elasticsearch: Custom Analyzer [analyzer_phrase] failed to find filter under name [icu_folding]====

Reinstall <tt>analysis-icu</tt> plugin (you need to do this after every Elasticsearch update, remember!):

 # /usr/share/elasticsearch/bin/elasticsearch-plugin remove analysis-icu
 # /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-icu
 # systemctl restart elasticsearch.service

====Elasticsearch exited unexpectedly, with exit code 137====

You probably don't have enough memory for what ES expects by default. Create a file under <tt>/etc/elasticsearch/jvm.options.d</tt> and add to it something like <tt>-Xms512m -Xmx512m</tt>. Search the internet for more information.

====Elasticsearch error after distro upgrade: <nowiki>[NoNodes] ** No nodes are available: [https://localhost:9200], called from sub Search::Elasticsearch::Role::Client::Direct::__ANON__</nowiki>====

This is common after an update to Debian 13 (due to changes in HTTP::Tiny 0.083+ library version that it ships [https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=38345#c26]). You need to add <code><nowiki><handle_args><verify_SSL>0</verify_SSL></handle_args></nowiki></code> to the <code><nowiki><elasticsearch></nowiki></code> section in your Koha configuration.

{{DevBook}} 

[[Category:Documentation]] 
[[Category:Installation]] 
[[Category:Debian Packages]] 
[[Category:Installation alternatives]]
