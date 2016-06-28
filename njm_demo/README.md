NJM Demo Application                                                                                                                                          
====================                                                                                                                                          
                                                                                                                                                              
This is a self contained demo of a simple application with a login screen / menu and various programs.                                                        
It's currently compiled and tested with Genero 3.00 against Informix.                                                                                         
                                                                                                                                                              
## Structure of folders:                                                                                                                                       
* db: core source to create and populate the database - also contains an Informix dbexport and an imp.sh to load it.
* etc: genero styles / action defaults / top menus / toolbars / schema files etc
* gas300: gas .xcf files for running the main menu and the web base order entry.
* pics: images used by the demos
* src: Genero source code
* src/forms: Genero screen forms
* src/lib: Genero library source code

## Building
The make file assume you have Genero Studio 3.00 installed and licensed.

* make - will use gsmake to build the project
* make packit - will us gsmake to build the project and produce a tgz file of the deployables.

## Running
The GAS xcf files assume you have a resource defined of res.path.isv - this should point to the base
directory. The expected path for the njm_demo application is: $(res.path.isv)/demos/njm_demo

## Deploying Using GAR
The make file can do this for you.
```
make deploy
```

## UNDeploying Using GAR
The make file can do this for you.
```
make undeploy
```

## Deploying Manually
So that folder is where to extract the njm_demo.tgz that the make packit will build, eg:
```
cd <your base directory>
mkdir -p demos/njm_demo
cd demos/njm_demo
tar xvzf <whereever>/njm_demo.tgz
```

Then either copy or symbolically link the gas300/ files to the folder you are using for your .xcf files.

## Database
To load the Informix database
```
$ cd db
$ tar xzf njm_demo.exp.tgz
$ export DBDATE=DMY4/
$ dbimport -d <whatever dbspace> njm_demo
```

## Running via the GAS
Once you have done the database and the 'make deploy' you should be able to run the demos.

```
http://<your server>/gas/ua/r/gweboe_def
```

and

```
http://<your server>/gas/ua/r/gdemo_def
```
