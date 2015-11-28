# Introduction #

To this page I will try to add everything I understand how works in the control4 communication protocols. If you have something to contribute with, don't hesitate to drop me a line or two by mail or something :)

# c4soap #

## GetVariable ##
Get the value of a variable.
  * iddevice: the id of the deviceto get the variable for
  * idvariable: the variable to retrieve. The only one I use so far is 1001, LIGHT\_LEVEL

```
<c4soap name="GetVariable" async="False">
 <param name = "iddevice" type = "INT">123</param>
 <param name = "idvariable" type = "INT">1001</param> 
</c4soap>
```

the reply will be of the form:

```
<c4soap name="GetVariable" seq="" result="1">
 <variable deviceid="123" variableid="1001" name="LIGHT_LEVEL" type="2" readonly="0" hidden="0" bindingid="0" bindingname="">30</variable>
</c4soap>
```

In this case 30 is the light level.

## GetVersionInfo ##
When the director have found a device to connect to, it uses the xml-rpc-soap'ish interface "c4soap".

**All commands are ended with one \x00 character.**

The first thing the client says when it connects are
```
<c4soap name="GetVersionInfo" async="False" />
```

Director will then respond to the GetVersionInfo command with something like
```
<c4soap name="GetVersionInfo" result="1">
  <versions>
    <version name="Director" version="1.3.2.318" buildtype="" builddate="Nov 13 2007" buildtime="17:45:35"/>
    <version name="MediaManager" version="1.3.2.318" buildtype="" builddate="Nov 13 2007" buildtime="17:58:55"/>
  </versions>
</c4soap>
```

Okay. Next step, pretty important

## EnableEvents ##

In the connection period, the composer also send this to the director
```
<c4soap name="EnableEvents" async="True">
  <param name="enable" type="bool">1</param>
</c4soap>
```
Which enables events to the composer, so, when stuff happens on the director, it will inform composer. Well, you get it. Events are events. And they are here enabled.



## GetItems ##
This will dump everything on the entire director. Pretty neat to get an overview :)
```
<c4soap name="GetItems" async="False">
  <param name="filter" type="number">0</param>
</c4soap>
```
The parameters values for the filter argument are:

  * Item Type = 2 = Site
  * Item Type = 3 = Building
  * Item Type = 4 = Floor
  * Item Type = 6 = Device Type
  * Item Type = 7 = Device
  * Item Type = 8 = Room


## GetBindingsByDevice ##

## GetMediaByDevice ##
Returns what media you have. You can ask for playlists etc. Later.

## GetNetworkBindings ##
This is very neat! You'll get information about all your dimmers etc, what MAC addresses, types etc they are, and what internal deviceid they are.

## GetPhysicalDevices ##
Extensive information of the one above. More devices etc. You'll pretty much get everything from above here as well i think.

# C4 Speakerpoint Audio #

The speakerpoint audio consists mainly of a RTP stream which only updates its sequence counter for each new song playes. But increments the timestamp value corresponding to the payloads mpeg frame number. The data is transfered over UDP to port 6200 of the receiving speakerpoint.

Firstly the server sends two 9 bytes long ASCII commands, expecting the commands to be sent as-is in return. (no encapsulation here)

```
> "SYNC     "
< "SYNC     "
```

```
> "MASTER   "
< "MASTER   "
```

After this, the server starts to transmit 639 bytes long packets containing a RTP wrapper and then raw MPEG/III data encapsulated in MPEG ADTS in the payload.

For each RTP packet sent, the server expects a UDP packet containing the timestamp value, in a 9 byte long zero-prepended string. (%09d)