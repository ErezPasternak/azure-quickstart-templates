# Creates Ericom Connect deployment

This template deploys the following resources:

<ul><li>storage account;</li><li>vnet, public ip, load balancer;</li><li>domain controller vm;</li><li>RD Gateway/RD Web Access vm;</li><li>RD Connection Broker/RD Licensing Server vm;</li><li>a number of RD Session hosts (number defined by 'numberOfRdshInstances' parameter)</li></ul>

The template will deploy DC, join all vms to the domain and configure RDS roles in the deployment.

Click the button below to deploy

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://azuredeploy.net/)