<%dsp:taglib name="btrack" prefix="bt" %>

<html>
<head><title>Bug Tracker - Admin - Platforms</title></head>

<body bgcolor="#FFFFFF">

<%dsp:include uri="header.dsp"/>

<center><h1>Manage Platforms</h1></center>

<bt:show-messages/>

<a href="record?id=new&type=Platform&origin=list-platforms">Click here to create a new platform.</a>
<br>Click any platform name to edit that platform.

<p>

<table border="1" width="95%" align="center">
  <bt:platform key="init_all" recordClass="sigue.btrack.Platform"/>
  <tr>
    <th nowrap>&nbsp;</th>
    <th nowrap>Name</th>
  </tr>
  <bt:iterate name="all_records" type="sigue.btrack.Platform">
    <bt:noRowsMessage>
      <tr><td colspan="4">There are no platforms to display.</td></tr>
    </bt:noRowsMessage>
    <bt:row>
      <tr>
        <td><bt:rowNumber/></td>
        <td><a href="record?id=<bt:platform key="id"/>&type=Platform"><bt:platform key="name"/></a></td>
      </tr>
    </bt:row>
  </bt:iterate>
</table>

<p>

<%dsp:include uri="footer.dsp"/>

</body>
</html>
