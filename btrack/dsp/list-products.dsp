<%dsp:taglib name="btrack" prefix="bt" />

<html>
<head><title>Bug Tracker - Admin - Products</title></head>

<body bgcolor="#FFFFFF">

<%dsp:include url="header.dsp"/>

<center><h1>Manage Products</h1></center>

<bt:show-messages/>

<a href="record?id=new&type=Product&origin=list-products">Click here to create a new product.</a>
<br>Click any product name to edit that product.

<p>

<table border="1" width="95%" align="center">
  <tr>
    <th nowrap>Name</th>
    <th nowrap>Owner</th>
    <th nowrap>Modules</th>
  </tr>
  <bt:iterate name="all_products" type="sigue.btrack.Product" beanId="product">
    <bt:noRowsMessage>
      <tr><td colspan="3">There are no products.</td></tr>
    </bt:noRowsMessage>
    <bt:row>
      <jsp:useBean id="product" scope="page" class="sigue.btrack.Product"/>
      <tr>
        <td><a href="record?id=<jsp:getProperty name="product" property="id"/>&type=Product"><jsp:getProperty name="product" property="name"/></a></td>
        <td><bt:product key="owner"/></td>
        <td><bt:product key="modules"/></td>
      </tr>
    </bt:row>
  </bt:iterate>
</table>

<p>

<%dsp:include url="footer.dsp"/>

</body>
</html>