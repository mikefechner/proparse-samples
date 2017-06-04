/*------------------------------------------------------------------------
    File        : simple.p
    Purpose     :

    Syntax      :

    Description :

    Author(s)   :
    Created     : Sun Jun 04 16:12:33 CEST 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

DEFINE VARIABLE i AS INTEGER NO-UNDO INITIAL 21 .

/* ***************************  Main Block  *************************** */

MESSAGE i * 2
    VIEW-AS ALERT-BOX.
