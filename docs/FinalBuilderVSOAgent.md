Visual Studio Online (VSO) FinalBuilder Agent
----------------------

To run the FinalBuilder Task on VSO you require an agent capable of running FinalBuilder. This means creating a VM on azure to run a VSO agent and install FinalBuilder on. 

Thankfully that are numerous articles online on how to setup an Azure VM to run a Team Foundation Build agent. The article [Configure a Build vNext Agent](http://nakedalm.com/configure-a-build-vnext-agent-on-vso/) from *naked ALM Consulting* is a great example of this. 

Once the agent is running and registered with VSO you will need to [Installing FinalBuilder](https://github.com/VSoftTechnologies/FinalBuilderTFS/blob/master/docs/InstallingFinalBuilder.md) so that it meets the "Demands" of the FinalBuilder task.
