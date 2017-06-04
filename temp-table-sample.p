/*------------------------------------------------------------------------
    File        : temp-table-sample.p
    Purpose     :

    Syntax      :

    Description :

    Author(s)   :
    Created     : Sun Jun 04 21:47:42 CEST 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE TEMP-TABLE ttCustomer NO-UNDO
    FIELD CustNumber LIKE Customer.CustNum
    FIELD CustName   LIKE Customer.Name
    FIELD Revenue    AS DECIMAL FORMAT ">>>,>>>,>>9.99" .

/* ***************************  Main Block  *************************** */

