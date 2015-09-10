Team Foundation Build FinalBuilder Task UI
==========================================

FinalBuilder General
----------------------

* ***FinalBuilder project*** - The repository location of the FinalBuilder script to run for the build. The repository location will be converted to an on disk location after the source is transfered to the build agent. 
* ***Working directory*** - The respositry directory that should be treated as the working directory for the FinalBuilder project run. By default this will be the base source directory if not set. 
* ***Drop folder*** - The network location to pass to the FinalBuilder script as the drop location for artifacts. In XAML builds having a drop folder was common, this option simply mimics that feature. By default the location is blank. 

Targets
----------------------

* ***Targets*** - A line seperated list of FinalBuilder project targets to run. The order of the targets is important and is honoured when running the FinalBuilder project. Dependencies are honoured, as well as the dependence chain functionality (i.e. not running dependencies more than once). By default the "default" target is run.

VS.Net Build
----------------------

For backwards compatiblity with XAML builds we offer the same options that were presented on our XAML activities. 

* ***Solution*** - The solution file to pass to the FinalBuilder script. The string can contain wild cards such as * and ? for matching one or more solution file. By default a blank value is passed. 
* ***Platform*** - The platform string to pass to the FinalBuilder script. By default this value is blank. 
* ***Flavor*** - The flavor string to pass to the FinalBuilder script. By default this value is blank. 
* ***Custom Arguments*** - The line seperated list of custom arguments to pass to the FinalBuilder script. The FinalBuilder "Get Team Foundation Build Parameters" action is limited to collection 10 of these parameters. In future we will be implementing passing FinalBuilder variables directly. By default a blank value is passed. 

Get Team Foundation Build Parameters
----------------------

Get Team Foundation Build Parameters action in FinalBuilder is the method of extracting the above variables and using them within a FinalBuilder script. Include this action, create variables for each of the parameters required for the build, and assign them as required. 