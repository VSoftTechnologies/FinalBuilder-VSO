Install FinalBuilder On Agent
----------------------

To install FinalBuilder you will need to grab the installer from the [FinalBuilder](https://www.finalbuilder.com/downloads/finalbuilder) website.

When installing FinalBuilder make sure to include the option to install FinalBuilder to the path. This will mean that the Team Foundation agent will be able to meet the demands on the FinalBuilder task. Demands work by checking the system path for a specified executable. If no agent matches the demands of the tasks with in the build queuing the build will generate a warning. 