<%dsp:taglib name="btrack" prefix="bt" %>
<jsp:useBean id="record" class="sigue.btrack.Module" scope="session"/>

<html>
<head><title>Bug Tracker - Admin - Edit Module</title></head>

<body bgcolor="#FFFFFF">

<%dsp:include uri="header.dsp"/>

<bt:show-messages/>

<center><h1>Edit Module</h1></center>

<form name="editModuleForm" method="post" action="record?action=save">
  <input type="hidden" name="type" value="Module">
  <table border="0">
    <tr>
      <td width="5%">&nbsp;</td>
      <td nowrap width="95%" colspan="3">
        <span class="fieldTitle">Module name:</span>
        <br><input name="name" type="text" size="30" maxlen="30"
                   value="<jsp:getProperty name="record" property="name"/>">
      </td>
    </tr>
    <tr>
      <td width="5%">&nbsp;</td>
      <td width="95%" colspan="3">
        <span class="fieldTitle">User with primary responsibility:</span>
        <br><input name="owner" type="text" size="30" maxlen="30"
                   value="<jsp:getProperty name="record" property="owner"/>">
      </td>
    </tr>
    <tr>
      <td width="5%">&nbsp;</td>
      <td width="95%" colspan="3">
        <input name="Submit" type="Submit" value="Submit">
      </td>
    </tr>
  </table>

</form>

<%dsp:include uri="footer.dsp"/>

</body>
</html>
