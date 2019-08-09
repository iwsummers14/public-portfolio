# public-portfolio
A public portfolio of things I've written.

## csharp
This folder contains a small MVC webapp I made that allowed co-workers to request database clones. It passed an XML file to a backend PowerShell script which processed the jobs.

## node.js
An example of a node.js application I wrote that is a Discord chatbot.
This bot connects to a MySQL database server and can do 'actions' or speak 'quotes'.
Commands issued in the chat channels can add quotes and actions to the database.
A version of this is running as a container on AWS with an RDS database backing it.

## powershell
Currently, these are miscellaneous PowerShell scripts that I have written. I plan to add more to this as I re-work some of my previous scripts.

## sql
These are examples of different SQL procedures I have written while administering Microsoft SQL Server.

## terraform
This is an example module I wrote to set up a small lab environment in Azure.  The environment includes a virtual network, two subnets, two VM's with NICs, and a network security group with an RDP-allow rule.  This was written in my home environment which features HashiCorp Vault for secrets, and a Consul backend that has been configured for ACLs.  

I wrote this to demonstrate terraform modules, backend configuration, variable definitions, variable files, and obtaining secrets from Vault.
