/*------------------------------------------------------------------------
    File        : customer-tt.p
    Purpose     :

    Syntax      :

    Description :

    Author(s)   :
    Created     : Sun Jun 04 20:42:39 CEST 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE TEMP-TABLE ttCustomer NO-UNDO
    LIKE Customer
    FIELD FieldOrderTotal AS DECIMAL .

/* ***************************  Main Block  *************************** */

RUN DoSomething (TABLE ttCustomer BY-REFERENCE) .

PROCEDURE DoSomething:

    DEFINE INPUT PARAMETER TABLE FOR ttCustomer .

    DEFINE BUFFER b_ttCustomer FOR ttCustomer .
    DEFINE BUFFER b2_ttCustomer FOR ttCustomer .

    FOR EACH ttCustomer:

    END.

    FOR FIRST ttCustomer:

    END.

    DO FOR b_ttCustomer:

    END.

    FIND FIRST b2_ttCustomer .

END.