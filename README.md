# chips-rundeck
Docker container for RunDeck used for control of CHIPS environments

This build extends the ch-serverjre image (https://github.com/companieshouse/docker-weblogic/tree/main/ch-serverjre) to create a RunDeck container.  

The container is preconfigured to support storage of RunDeck projects and keys in an Oracle database and to use ActiveDirectory LDAP for authentication.  The authorisation (role membership) is determined by a realm.properties file that is bind mounted into the container at runtime.

An example docker-compose.yml file is provided.

### Run time environment properties file
In order to use the image, a number of environment properties need to be defined in a file, held locally to where the docker command is being run - for example, `rundeck.properties` 
|Property|Description  |Example
|--|--|--
|RUNDECK_JVM_OPTIONS |The JVM options, such as heap size and JAAS configuration to use when starting RunDeck.  ``-Drundeck.jaaslogin=true -Dloginmodule.conf.name=jaas-ldap.conf -Dloginmodule.name=multiauth`` is needed if using LDAP for authentication.|``-Xmx4096m -Xms256m -XX:MaxMetaspaceSize=256m -server -Drundeck.jaaslogin=true -Dloginmodule.conf.name=jaas-ldap.conf -Dloginmodule.name=multiauth``
|RUNDECK_SERVER_URL|The url that is used by web browsers to access the service|``https://rundeck.staging.heritage.aws.internal``
|LDAP_PROVIDER_URL|The url of the ldap server|``ldaps://ldap.my.server:636``
|LDAP_BIND_DN|The distinguished name of the user to bind with|``CN=myldapbinduser,OU=AD Groups,OU=TEST,OU=MYORG,DC=MYDC,DC=local``
|LDAP_BIND_PASSWORD|The password of the user to bind with|``mypassword``
|LDAP_BASE_DN|The base distinguished name under which to search for users when authenticating|``OU=TEST,OU=MYORG,DC=MYDC,DC=local``
|LDAP_ROLE_BASE_DN|The base distinguished name under which to search for roles|``OU=TEST,OU=MYORG,DC=MYDC,DC=local``
|RUNDECK_DATABASE_URL|The jdbc url to connect to the Oracle database with|``jdbc:oracle:thin:@my-db.staging.heritage.aws.internal:1529:MYDB``
|RUNDECK_DATABASE_USERNAME|The database username|``myusername``
|RUNDECK_DATABASE_PASSWORD|The database user password|``mypassword``
|RUNDECK_SERVER_UUID|A unique identifier for the Rundeck server.  Used by Rundeck when storing and then retrieving the SCM configuration from the DB.|``db20fdb5-b506-479a-baf2-68ea6fbf04c2``
|TZ|The timezone that Rundeck uses. This is important for having consistent run times throughout the year when scheduling jobs.|``Europe/London``
|SLACK_WEBHOOK_TOKEN|An environment specific token for using the Slack notification plugin.  This allows a different webhook to be used in Staging and Live so that the notifications go to different Slack channels, such as ``#rundeck_test`` and ``#rundeck_prod``|``T0ABCDEFG/blahblah/blahblahblahblahblah``
|CONCOURSE_TOKEN|A definition of the user, token and role for a static token that can be used to invoke the Rundeck API.  Referenced in ``/apps/rundeck/etc/tokens.properties.template``|``someuser: XXXxxxBlahSecretTokenBlahxxxXXX, somerole``
|EMAIL_SERVER_HOST|The email (SMTP) server to use for email notifications|``my-smtp-server.blah.aws``
|EMAIL_SERVER_FROM_ADDRESS|The email address to use in the FROM field when sending email notifications|``rundeck@myemailaddress.com``
|CSI_EMAIL_ADDRESSES|The email address(es) for notifications to the CSI team in Companies House.  This can be a comma separated list of email addresses or a single email address.  This can be referenced in Rundeck with ``${globals.csi-email-addresses}``|``csi@myemailaddress.com``
|FESS_EMAIL_ADDRESSES|The email address(es) for notifications to the FESS team in Companies House. This can be a comma separated list of email addresses or a single email address.  This can be referenced in Rundeck with ``${globals.fess-email-addresses}``|``fess@myemailaddress.com``
|INSTANCE_NAME|A string that is displayed on the login page and in the top menu bar|``Live Environment``
|INSTANCE_NAME_BACKGROUND_COLOUR|The colour of the background for the INSTANCE_NAME string|``#123456``
|INSTANCE_NAME_TEXT_COLOUR|The colour of the text for the INSTANCE_NAME string|``#000000``


### Building the image
To build the image, from the root of this repo, run:

    docker build -t chips-rundeck .

The build expects the following in the root of the checked out repo:
- A rundeck war install package - e.g. rundeck-#.#.#-########.war.

The build will extract and/or install the following optional packages if present in the ``bin`` folder:
- The AWS CLI install package - i.e. awscli-exe-linux-x86_64-#.#.#.zip
- JMeter - i.e. apache-jmeter-#.#.zip

Those packages are put into place by a Concourse pipeline in CH, but can be manually placed if building locally.  
