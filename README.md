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


### Building the image
To build the image, from the root of this repo, run:

    docker build -t chips-rundeck .

The build expects there to be a rundeck war installer package in the root of the repo - e.g.  rundeck-#.#.#-########.war.