# PSSeCo

 ModuleName		:	PSSeCo.psm1
 
 Author			:	Dinesh Paskaran 
 
 Version		:	1.0.0
 
 Month-Year		:	17.01.2015
 
 Purpose		:	Module to create a communication channel between 
 					Sessions.
					This module needs the module 
					https://github.com/RamblingCookieMonster/PSSQLite
					to work! 
					Please download PSSQLite and install it into your Windows Module Folder.
					Also install this module within your Windows  Module Folder

# How To Use
1. Initialize-PSSeCoChannel
- To initialize a channel for the communication use the function Initialize-PSSeCoChannel. Provide a ChannelPath and a ChannelName
- Make sure you use the same ChannelPath and ChannelName for all PowerShell sessions which should communicate with each other.
