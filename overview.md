FinalBuilder Build Task
==========================================

![](https://github.com/VSoftTechnologies/FinalBuilderTFS/blob/master/docs/images/FinalBuilderTaskOptionsAll.png)

FinalBuilder General
----------------------

* ***FinalBuilder project*** - The repository location of the FinalBuilder script to run for the build. The repository location will be converted to an on disk location after the source is transferred to the build agent. 
* ***Working directory*** - The repository directory that should be treated as the working directory for the FinalBuilder project run. By default this will be the base source directory if not set. 
* ***Drop folder*** - The network location to pass to the FinalBuilder script as the drop location for artefacts. In XAML builds having a drop folder was common, this option simply mimics that feature. By default the location is blank. 

Targets
----------------------

* ***Targets*** - A line separated list of FinalBuilder project targets to run. The order of the targets is important and is honoured when running the FinalBuilder project. Dependencies are honoured, as well as the dependence chain functionality (i.e. not running dependencies more than once). By default the "default" target is run.

VS.Net Build
----------------------

For backwards compatibility with XAML builds we offer the same options that were presented on our XAML activities. 

* ***Solution*** - The solution file to pass to the FinalBuilder script. The string can contain wild cards such as * and ? for matching one or more solution file. By default a blank value is passed. 
* ***Platform*** - The platform string to pass to the FinalBuilder script. By default this value is blank. 
* ***Flavor*** - The flavor string to pass to the FinalBuilder script. By default this value is blank. 
* ***Custom Arguments*** - The line separated list of custom arguments to pass to the FinalBuilder script. The FinalBuilder "Get Team Foundation Build Parameters" action is limited to collection 10 of these parameters. In future we will be implementing passing FinalBuilder variables directly. By default a blank value is passed. 

Get Team Foundation Build Parameters
----------------------

Get Team Foundation Build Parameters action in FinalBuilder is the method of extracting the above variables and using them within a FinalBuilder script. Include this action, create variables for each of the parameters required for the build, and assign them as required. 

![](https://github.com/VSoftTechnologies/FinalBuilderTFS/blob/master/docs/images/GetTeamFoundationBuildParameters.png)

All the following parameters are either provided by the FinalBuilder task or from the environment variables provided by the agent runner.

* ***Team Server URL*** - The URL to the Team Foundation Server running the build.  
* ***Team Project*** - The Team Foundation Project the build is running under.   
* ***Build Id*** - The build number of the build currently running. 
* ***Platform*** - The platform text specified in the FinalBuilder task UI. 
* ***Flavor*** - The flavor text specified in the FinalBuilder task UI.
* ***Default solution file*** - The first solution found from the "Solution" search string in the FinalBuilder task UI.
* ***Solution file list*** - The full list of solutions found from the "Solution" search string in the FinalBuilder task UI. Separated by new lines. 
* ***Deployment folder*** - The network folder specified by the "Drop folder" in the FinalBuilder task UI.  
* ***Solution root folder*** - The root directory on the agent to which the source was copied. 
* ***Working directory*** - The working directory set in the FinalBuilder task UI. 

![](https://github.com/VSoftTechnologies/FinalBuilderTFS/blob/master/docs/images/GetTeamFoundationBuildParameters_CustomArgs.png)

* ***Custom Argument 1 to 10*** - Each of the first 10 lines of arguments added to the "Custom Arguments" field in the FinalBuilder task UI.
