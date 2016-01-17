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
 * To initialize a channel for the communication use the function Initialize-PSSeCoChannel. Provide a ChannelPath and a ChannelName
 * Make sure you use the same ChannelPath and ChannelName for all PowerShell sessions which should communicate with each other.
 
    `Initialize-PSSeCoChannel -ChannelName "test" -ChannelPath "C:\channels"`
 
2. Send-PSSeCoMessage
 * Use this function to send a message to a channel.
 * The CommunicationId defines a group. This Id allows you to generate multiple communication within one channel. 
 * I recomend to use two CommunicationIds between two PowerShell sessions: One for sending message from A to B and the other for sending message from B to A.
    `Send-PSSeCoMessage -Message "Hello World!" -CommunicationId "communication1234" -ChannelName "test" -ChannelPath "C:\channels"`
3. Get-PSSeCoMessage
 * This function returns the last message from the channel.
 * If you want to wait until a message arrived, you have to set
 the $WaitUntilMessageRead - Switch. This is a blocking operation,
 this will wait until a message is arrived in the channel with 
 correct communication id. 
 * If you want to wait until a message arrives and still dont want to wait forever you can set the MaxWaitSeconds to a value larger than '0'. The Function will only wait until the message arrived or the time is up.
 * If you want to delete the last read message from the channel set the DeleteOldMessage - Switch. But note if two sessions with same communication id listen on the same channel with the DeleteOldMessage Switch set,then a concurrency problem can occur.
      
4. Clear-PSSeCoChannel
 * This function clear all messages with given communication id from the channel. 
     
5.  Stop-PSSeCoChannel
 * This function stops the initialized channel. Make sure you passed the correct ChannelName and ChannelPath as used for Initialize-PSSeCoChannel. Use this function when you think the communication channel should now be cleared and removed.
