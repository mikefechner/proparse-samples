/**********************************************************************
 * Copyright (C) 2006-2016 by Consultingwerk Ltd. ("CW") -            *
 * www.consultingwerk.de and other contributors as listed             *
 * below.  All Rights Reserved.                                       *
 *                                                                    *
 *  Software is distributed on an "AS IS", WITHOUT WARRANTY OF ANY    *
 *   KIND, either express or implied.                                 *
 *                                                                    *
 *  Contributors:                                                     *
 *                                                                    *
 **********************************************************************/
/*------------------------------------------------------------------------
    File        : BufferHelper
    Purpose     :
    Syntax      : Static methods only, private constructor to disallow
                  instance creation
    Description :
    Author(s)   : Mike Fechner / Consultingwerk Ltd.
    Created     : Wed Sep 30 14:43:37 CEST 2009
    Notes       :
  ----------------------------------------------------------------------*/

ROUTINE-LEVEL ON ERROR UNDO, THROW.

USING Consultingwerk.*                       FROM PROPATH .
USING Consultingwerk.Util.*                  FROM PROPATH .
USING Progress.Lang.*                        FROM PROPATH .

CLASS Consultingwerk.Util.BufferHelper:

    /**
     * Purpose: Protected default constructor.
     * Notes:   There's no need to create instances of the helper classes
     */
    CONSTRUCTOR PROTECTED BufferHelper ():
        SUPER ().

    END CONSTRUCTOR.

    /**
     * Purpose: Returns the handle to the database buffer referenced by the
     *          BufferFieldName object
     * Notes:
     * @param poBufferFieldName The reference to the BufferFieldName object
     * @return The handle to the buffer references by the BufferFieldName object
     */
    METHOD PUBLIC STATIC HANDLE BufferHandle (poBufferFieldName AS BufferFieldName):

        DEFINE VARIABLE hBuffer AS HANDLE NO-UNDO.

        IF poBufferFieldName:DatabaseName > "":U AND poBufferFieldName:TableName > "":U THEN
            CREATE BUFFER hBuffer FOR TABLE SUBSTITUTE ("&1.&2":U,
                                                        poBufferFieldName:DatabaseName,
                                                        poBufferFieldName:TableName) .
        ELSE
            CREATE BUFFER hBuffer FOR TABLE poBufferFieldName:TableName .

        RETURN hBuffer.

    END METHOD .

    /**
     * Purpose: Tests if the passed in buffer handle has a field with the
     *          given name
     * Notes:   Verifies that a valid buffer is passed in first.
     * @param phBuffer The Buffer handle to test
     * @param pcFieldName The name of the buffer field
     * @return Logical value indicating if the field exists
     */
    METHOD PUBLIC STATIC LOGICAL HasField (phBuffer AS HANDLE,
                                           pcFieldName AS CHARACTER):

        DEFINE VARIABLE hField AS HANDLE NO-UNDO.

        {Consultingwerk/Assertion/HandleAssert/ValidHandle.i phBuffer """BUFFER"":U"} .

        hField = phBuffer:BUFFER-FIELD (pcFieldName) NO-ERROR .

        RETURN VALID-HANDLE (hField) .

        FINALLY:
            ERROR-STATUS:ERROR = FALSE NO-ERROR .
        END FINALLY.

    END METHOD.

    /**
     * Purpose: Parses a field name
     * Notes:   Supports db.table.field, table.field, field with and without index (extent)
     * @param pcFieldName The field name to parse
     * @return The Consultingwerk.BufferFieldName struct describing the field name
     */
    METHOD PUBLIC STATIC BufferFieldName ParseFieldName (pcFieldName AS CHARACTER):

        RETURN NEW BufferFieldName (pcFieldName) .

    END METHOD .

END CLASS.
