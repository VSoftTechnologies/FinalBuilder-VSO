FinalBuilder Task Installation
----------------------

To use the FinalBuilder Task in Team Foundation Build the task needs to be uploaded to your Team Foundation Server (TFS). This can either be your Visual Studio Online (VSO) account or an on premises TFS installation. 

Uploading the task requires the use of this repository, npm, and a microsoft tool called tfx-cli. Below we provide the steps to install the FinalBuilder Task onto TFS from scratch.   

## Repository Clone

To clone this repository use the following command line. You will require git to be installed and available on your path. 

```
> mkdir VSoft
> cd VSoft
> git clone https://github.com/VSoftTechnologies/FinalBuilderTFS.git

Cloning into 'FinalBuilderTFS'...
remote: Counting objects: X, done.
remote: Compressing objects: 100% (X/X), done.
remote: Total X (delta 0), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (X/X), done.
Checking connectivity... done.
```

With the repository cloned we require the TFS Extensions Command Line Utility (tfx-cli). It comes as a Node Package Manager (npm) package. Npm comes with both the [node.js](https://nodejs.org/en/download/) and [io.js](https://iojs.org/en/) installer. Download the installer for your Windows platform and run it. 

To check that NPM is working correctly you can use the npm version command

```
> npm -v

2.10.1
```

Now your able to install the tfx-cli package using npm. Install this globally so that its accessable on the command line. The comand line for this is as follows;

```
> npm install -g tfx-cli

tfx-cli@0.1.11 C:\Users\<username>\AppData\Roaming\npm\node_modules\tfx-cli
├── os-homedir@1.0.1
├── async@1.4.2
├── colors@1.1.2
├── minimist@1.2.0
├── node-uuid@1.4.3
├── q@1.4.1
├── read@1.0.7 (mute-stream@0.0.5)
├── validator@3.43.0
├── shelljs@0.5.3
├── vso-node-api@0.3.4
└── archiver@0.14.4 (buffer-crc32@0.2.5, lazystream@0.1.0, async@0.9.2, readable-stream@1.0.33, tar-stream@1.1.5, glob@4.3.5, lodash@3.2.0, zip-stream@0.5.2)
```

To test that tfx-cli is working correctly and is on the path use the tfx command. 

```
> tfx

Copyright Microsoft Corporation
tfx <command> [<subcommand(s)> ...] [<args>] [--version] [--help] [--json]

                        fTfs
                      fSSSSSSSs
                    fSSSSSSSSSS
     TSSf         fSSSSSSSSSSSS
     SSSSSF     fSSSSSSST SSSSS
     SSfSSSSSsfSSSSSSSt   SSSSS
     SS  tSSSSSSSSSs      SSSSS
     SS   fSSSSSSST       SSSSS
     SS fSSSSSFSSSSSSf    SSSSS
     SSSSSST    FSSSSSSFt SSSSS
     SSSSt        FSSSSSSSSSSSS
                    FSSSSSSSSSS
                       FSSSSSSs
                        FSFs    (TM)

commands:
   build
        manage task extensions and builds

   help
        command help

   login
        login and cache credentials. types: pat (default), basic
        login <collection url> [--authtype <authtype>] [options]

   parse
        parse json by piping json result from another tfx command
        parse <jsonfilter> [options]

   version
        output the version
        version [options]


Options:
   --help    : get help on a command
   --json    : output in json format.  useful for scripting
```

For tfx-cli to upload a task to TFS it needs to be logged in. We can do this once so that all following commands will use the some credentials. The method used depends on whether your using VSO or an On Prem installation. 

## On Prem Login
----------------------

For on premises TFS basic authentication will need to be enabled. The tfx-cli project has a great guide on how to achieve this [Using tfx against Team Foundation Server (TFS) 2015 using Basic Authentication](https://github.com/Microsoft/tfs-cli/blob/master/docs/configureBasicAuth.md).

Once TFS has been configured to use basic authentication use the tfx-cli login command to connect to TFS. You will be prompted for the TFS collection URL to connect to, and the username and password for accesssing that collection. 

```
> tfx login --authType basic

Copyright Microsoft Corporation

Enter collection url > http://<server>:<port>/tfs/<collection>
Enter username > <user>@<domain>
Enter password > <password>
logged in successfully
```

With a succesful login subsequent commands will not require us to provide the credentials again. 

## Visual Studio Online (VSO) Login
----------------------

For VSO login you need a personal access token setup under your account. There is a great article to configure an access token located at [Using Personal Access Tokens to access Visual Studio Online](http://roadtoalm.com/2015/07/22/using-personal-access-tokens-to-access-visual-studio-online/).

With the personal access token configured use the tfx-cli login command to connect to VSO. You will be prompted for the TFS collection URL to connect to, and access token for accesssing that collection.

```
> tfx login

Copyright Microsoft Corporation

Enter collection url > https://<vsoname>.visualstudio.com/<collection>
Enter personal access token > <access token>
logged in successfully
```

With a succesful login subsequent commands will not require us to provide the credentials again. 

## Uploading Task
----------------------

Once logged into TFS we are able to upload the FinalBuilder task to the server. Tasks are uploaded to the server, the server will then pass them onto agents requried to run those tasks. 

To upload the task use the tfx-cli tasks upload command. Each command shown below is a sub-command of the previous, so order does matter here. The overwrite option is included so that any previously installed version is overwritten. Note however the highest version number of the task will win when running builds.

* Note: This command is run under the directory in which this repositry was cloned to (i.e. FinalBuilderTFS). *  

```
> tfx build tasks upload ./FinalBuilder --overwrite

Copyright Microsoft Corporation

task at: ./FinalBuilder uploaded successfully!
```

To test that the FinalBuilder task is now installed on the builds page for teh collection the task was uploaded to. Create a new empty Team Foundation Build definition. After clicking "Add build step" a FinalBuilder task should appear in the "Build" category. 


## Further Steps
----------------------

For more information on the following subjects please follow the links;

* How to configure the build task refer to [Task UI](https://github.com/VSoftTechnologies/FinalBuilderTFS/blob/master/docs/TaskUI.md).
* How to install FinalBuilder on an agent refer to [Installing FinalBuilder](https://github.com/VSoftTechnologies/FinalBuilderTFS/blob/master/docs/InstallingFinalBuilder.md).
* How to create a FinalBuilder VSO agent refer to [Creating a VSO FinalBuilder Agent](https://github.com/VSoftTechnologies/FinalBuilderTFS/blob/master/docs/FinalBuilderVSOAgent.md).