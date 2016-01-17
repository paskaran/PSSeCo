<#

The MIT License (MIT)

Copyright (c) 2016 Dinesh Paskaran.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. #>

<#------------------------------------------------------------------- 
 ModuleName		:	PSSeCo.psm1
---------------------------------------------------------------------
 Author			:	Dinesh Paskaran 
---------------------------------------------------------------------
 Version		:	1.0.0
---------------------------------------------------------------------
 Month-Year		:	17.01.2015
---------------------------------------------------------------------
 Purpose		:	Module to create a communication channel between 
 					Sessions.
					This module needs the module 
					https://github.com/RamblingCookieMonster/PSSQLite
					to work! 
					Please download PSSQLite and install it into your 
					Windows Module Folder.
					Also install this module within your 
					Windows  Module Folder
---------------------------------------------------------------------
 How To Use		:	1. Initialize-PSSeCoChannel
 					-	To initialize a channel for the communication 
						use the function Initialize-PSSeCoChannel.
						Provide a ChannelPath and a ChannelName
					-	Make sure you use the same ChannelPath and 
						ChannelName for all PowerShell sessions which
						should communicate with each other.
						
					2.	Send-PSSeCoMessage
					-	Use this function to send a message to a 
						channel.
					-	The CommunicationId defines a group. This Id
						allows you to generate multiple communication
						within one channel. I recomend to use two 
						CommunicationIds between two PowerShell sessions:
						One for sending message from A to B and the other
						for sending message from B to A.
					
					3.	Get-PSSeCoMessage
					-	This function returns the last message from the channel.
					-	If you want to wait until a message arrived, you have to set
						the $WaitUntilMessageRead - Switch. This is a blocking operation,
						this will wait until a message is arrived in the channel with 
						correct communication id. 
					-	If you want to wait until a message arrives and still dont want to wait
						forever you can set the MaxWaitSeconds to a value larger than '0'.
						The Function will only wait until the message arrived or the time is up.
					-	If you want to delete the last read message from the channel set the
						DeleteOldMessage - Switch. But note if two sessions with same 
						communication id listen on the same channel with the 
						DeleteOldMessage Switch set,then a concurrency problem can occur.
						
					4.	Clear-PSSeCoChannel
					-	This function clear all messages with given communication id from the
						channel. 
					
					5. 	Stop-PSSeCoChannel
					-	This function stops the initialized channel. Make sure you passed the 
						correct ChannelName and ChannelPath as used for Initialize-PSSeCoChannel.
						Use this function when you think the communication channel 
						should now be cleared and removed.
					
---------------------------------------------------------------------
#>

# Import SQLite Module
Import-Module  PSSQLite
Write-Host "Loaded PSSeCo";
# PSSeCo File Suffix
$PSSECO_SUFFIX = ".psseco";

Function Generate-PSSeCoChannelPath{
	param(
		[String] $ChannelPath,
		[String] $ChannelName
	)
	$DataSourcePath = ($ChannelPath+"\"+$ChannelName+$PSSECO_SUFFIX);
	if($ChannelPath.EndsWith("\")){
		$DataSourcePath = ($ChannelPath+"\"+$ChannelName+$PSSECO_SUFFIX);
	}
	return $DataSourcePath;
}

# Initialize new channel
Function Initialize-PSSeCoChannel{
	param(
		[String] $ChannelPath,
		[String] $ChannelName
	)
	
	$Query = "CREATE TABLE IF NOT EXISTS message (
	        id INTEGER PRIMARY KEY AUTOINCREMENT,
	        com_id TEXT,
	        content TEXT)";
	$Result = (Invoke-SqliteQuery -Query $Query -DataSource (Generate-PSSeCoChannelPath -ChannelPath $ChannelPath -ChannelName $ChannelName ));
	Write-Host "Channel created at location $ChannelPath with following result=($Result)";
	
}

# Stops channel
Function Stop-PSSeCoChannel{
	param(
		[String] $ChannelPath,
		[String] $ChannelName
	)
	Remove-Item -Path (Generate-PSSeCoChannelPath -ChannelPath $ChannelPath -ChannelName $ChannelName ) -Force;
	Write-Host "Channel closed!";
}

# Delete old messages
Function Clear-PSSeCoChannel {
	param(
		[String] $CommunicationId,
		[String] $ChannelPath,
		[String] $ChannelName
	)
	[String] $DeleteEntry = "DELETE FROM message WHERE com_id='$CommunicationId'";
	Invoke-SqliteQuery -Query ($DeleteEntry) -DataSource (Generate-PSSeCoChannelPath -ChannelPath $ChannelPath -ChannelName $ChannelName );
}

# Function for send a message to listen group
Function Send-PSSeCoMessage{
	param(
		[String] $Message,
		[String] $CommunicationId,
		[String] $ChannelPath,
		[String] $ChannelName
	)
	$Message = $Message.Replace("'","%27");
	# Write message to db
	$Insert = "INSERT INTO message (com_id, content) VALUES ('$CommunicationId','$Message')";
	Invoke-SqliteQuery -Query $Insert -DataSource (Generate-PSSeCoChannelPath -ChannelPath $ChannelPath -ChannelName $ChannelName ); 
	
}

<#
Blocking and Non-Blocking read of last message with given communication id, channelname and channelpath
If the DeleteOldMessage - Switch is set, then the last read entry to the given
Communication Id will be deleted from the channel. Use this to prevent unnecessary storing of 
old messages. 

#>
Function Get-PSSeCoMessage{
	param(
		[String] $CommunicationId,
		[String] $ChannelPath,
		[String] $ChannelName,
		[Switch] $DeleteOldMessage,
		[Switch] $WaitUntilMessageRead,
		[Int]	 $MaxWaitSeconds = 0
	)
	 
	[String] $LockQuery = "SELECT * FROM message WHERE com_id='$CommunicationId' ORDER BY id DESC LIMIT 0,1";
	[String] $Query = "SELECT * FROM message WHERE com_id='$CommunicationId' ORDER BY id DESC LIMIT 0,1";
	[String] $DeleteEntry = "DELETE FROM message WHERE com_id='$CommunicationId' AND id=ENTRY_ID";
	$Result = $null;
	$MaxCount = 0;
	while($true){
		$Result = Invoke-SqliteQuery -Query $Query -DataSource ($ChannelPath+"\"+$ChannelName+$PSSECO_SUFFIX);
		if(($Result -ne $null) -and ($DeleteOldMessage)){
		 	# Read last message and delete entry before return (this is a non-atomic invoke, therefore it could happend,
			# that the entry will be deleted by another session which also listen on the same channel AND communication_id.
		 	Invoke-SqliteQuery -Query ($DeleteEntry.Replace("ENTRY_ID", $Result.id)) -DataSource ($ChannelPath+"\"+$ChannelName+$PSSECO_SUFFIX);
		}
		if($WaitUntilMessageRead){
			if($MaxWaitSeconds -gt 0){
				if($MaxCount -lt $MaxWaitSeconds){
					$MaxCount = $MaxCount + 1;
					# Wait Until is limited to given time of seconds
					if($Result -eq $null){
						Start-Sleep -Seconds 1;
					}
				}else{
					if($Result -ne $null){
						return $Result.content;
					}else{
						return $null;
					}				
				}
				
				
			}
			if(($Result -ne $null)){
				return $Result.content;
			}
		}else{
			if($Result -ne $null){
				return $Result.content;
			}else{
				return $null;
			}
		} 
	}
	
}



