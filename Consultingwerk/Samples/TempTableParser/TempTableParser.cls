/*------------------------------------------------------------------------
    File        : TempTableParser
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : Mike Fechner / Consultingwerk Ltd.
    Created     : Sun Jun 04 21:22:27 CEST 2017
    Notes       :
  ----------------------------------------------------------------------*/

BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Consultingwerk.*                                 FROM PROPATH .
USING Consultingwerk.Studio.Proparse.*                 FROM PROPATH .
USING Consultingwerk.Util.*                            FROM PROPATH .
USING com.joanju.proparse.NodeTypes                    FROM ASSEMBLY .
USING org.prorefactor.core.JPNode                      FROM ASSEMBLY .
USING org.prorefactor.treeparser.*                     FROM ASSEMBLY .
USING Progress.Lang.*                                  FROM PROPATH .

CLASS Consultingwerk.Samples.TempTableParser.TempTableParser:

    { Consultingwerk/BusinessEntityDesigner/Services/eField.i }

    /*------------------------------------------------------------------------------
        Purpose: Processes a Field Node
        Notes:
        @param poNode The JPNode pointing to the FIELD definition
        @param pcTable The current temp-table name
        @param piIndex The Field index
    ------------------------------------------------------------------------------*/
    METHOD PROTECTED VOID ProcessFieldNode (poNode AS JPNode,
                                            pcTable AS CHARACTER,
                                            piIndex AS INTEGER):

        DEFINE VARIABLE oSubNode      AS JPNode          NO-UNDO .
        DEFINE VARIABLE oFieldRefNode AS JPNode          NO-UNDO .
        DEFINE VARIABLE oIdNode       AS JPNode          NO-UNDO .
        DEFINE VARIABLE oArrayNode    AS JPNode          NO-UNDO .
        DEFINE VARIABLE cValue        AS CHARACTER       NO-UNDO .
        DEFINE VARIABLE lValue        AS LOGICAL         NO-UNDO .
        DEFINE VARIABLE oBufferField  AS BufferFieldName NO-UNDO .
        DEFINE VARIABLE hBuffer       AS HANDLE          NO-UNDO .
        DEFINE VARIABLE hBufferField  AS HANDLE          NO-UNDO .
        DEFINE VARIABLE oInitialNode  AS JPNode          NO-UNDO .

        CREATE eField.
        ASSIGN eField.TempTableName = pcTable
               eField.FieldOrder    = piIndex .

        oSubNode = ProparseHelper:FindChildNodeOfNodeType (poNode, "ID":U) .

        IF VALID-OBJECT (oSubNode) THEN
            eField.FieldName = oSubNode:getText () .

        /* LIKE Definition */
        oSubNode = ProparseHelper:FindChildNodeOfNodeType (poNode, "LIKE":U) .

        IF VALID-OBJECT (oSubNode) THEN DO:
            ASSIGN oFieldRefNode = ProparseHelper:FindChildNodeOfNodeType (oSubNode, "Field_ref":U) .

            IF VALID-OBJECT (oFieldRefNode) THEN DO:
                ASSIGN oIdNode = ProparseHelper:FindChildNodeOfNodeType (oFieldRefNode, "ID":U) .

                IF VALID-OBJECT (oIdNode) THEN DO ON ERROR UNDO, THROW:

                    oBufferField = BufferHelper:ParseFieldName (oIdNode:getText ()) .

                    hBuffer = BufferHelper:BufferHandle (oBufferField) .

                    IF VALID-HANDLE (hBuffer) AND BufferHelper:HasField (hBuffer, oBufferField:FieldName) THEN DO:
                        ASSIGN hBufferField = hBuffer:BUFFER-FIELD (oBufferField:FieldName)

                               eField.FieldDataType = hBufferField:DATA-TYPE
                               eField.FieldInitial  = hBufferField:DEFAULT-VALUE
                               eField.FieldLabel    = hBufferField:LABEL
                               eField.FieldFormat   = hBufferField:FORMAT
                               eField.FieldExtent   = hBufferField:EXTENT
                            .
                    END.

                    /* Mike Fechner, Consultingwerk Ltd. 28.09.2012
                       When the LIKE definition was LIKE an individual array element, don't
                       set the EXTENT value */
                    ASSIGN oArrayNode = ProparseHelper:FindChildNodeOfNodeType (oFieldRefNode, "Array_subscript":U) .

                    IF VALID-OBJECT (oArrayNode) THEN
                        eField.FieldExtent = 0 .

                    FINALLY:
                        GarbageCollectorHelper:DeleteObject (hBuffer) .
                    END FINALLY.

                END.
            END.
        END.

        oSubNode = ProparseHelper:FindChildNodeOfNodeType (poNode, "AS":U) .

        IF VALID-OBJECT (oSubNode) THEN DO:
            eField.FieldDataType = oSubNode:firstChild ():getText () .

            IF eField.FieldDataType = "PROGRESS.LANG.OBJECT":U THEN
                eField.FieldDataType = "PROGRESS.LANG.OBJECT":U .
        END.

        /* Extent */
        ASSIGN cValue = THIS-OBJECT:GetFieldAttributeValue (poNode, "EXTENT":U) .

        IF cValue > "":U THEN
            eField.FieldExtent = INTEGER (cValue) NO-ERROR  .

        /* Format */
        ASSIGN cValue = THIS-OBJECT:GetFieldAttributeValue (poNode, "FORMAT":U) .

        IF cValue > "":U THEN
            eField.FieldFormat = cValue .

        /* INITIAL */
        ASSIGN cValue = THIS-OBJECT:GetFieldAttributeValue (poNode, "INITIAL":U) .

        /* INITIAL ? */
        ASSIGN lValue       = FALSE
               oInitialNode = ProparseHelper:FindChildNodeOfNodeType (poNode, "INITIAL":U) .

        IF VALID-OBJECT (oInitialNode) THEN
            ASSIGN lValue = ProparseHelper:HasChildNodeOfNodeType (oInitialNode, "UNKNOWNVALUE":U) .

        IF lValue = TRUE THEN DO:
            ASSIGN eField.FieldInitialUnknownValue = TRUE
                   eField.FieldInitial             = "":U .
        END.
        ELSE IF cValue > "":U THEN
                eField.FieldInitial = cValue .

        /* Label */
        ASSIGN cValue = THIS-OBJECT:GetFieldAttributeValue (poNode, "LABEL":U) .

        IF cValue > "":U THEN
            eField.FieldLabel = cValue .

        /* Label */
        ASSIGN cValue = THIS-OBJECT:GetFieldAttributeValue (poNode, "LABEL":U) .

        IF cValue > "":U THEN
            eField.FieldLabel = cValue .

        /* SerializeName */
        ASSIGN cValue = THIS-OBJECT:GetFieldAttributeValue (poNode, "SERIALIZENAME":U) .

        IF cValue > "":U THEN
            eField.FieldSerializeName = cValue .

        /* XML Data Type */
        ASSIGN cValue = THIS-OBJECT:GetFieldAttributeValue (poNode, "XMLDATATYPE":U) .

        IF cValue > "":U THEN
            eField.FieldXmlDataType = cValue .

        /* XML Node Type */
        ASSIGN cValue = THIS-OBJECT:GetFieldAttributeValue (poNode, "XMLNODETYPE":U) .

        IF cValue > "":U THEN
            eField.FieldXmlNodeType = cValue .

        /* XML Node Name */
        ASSIGN cValue = THIS-OBJECT:GetFieldAttributeValue (poNode, "XMLNODENAME":U) .

        IF cValue > "":U THEN
            eField.FieldXmlNodeName = cValue .

        /* Serialize Hidden */
        IF VALID-OBJECT (ProparseHelper:FindChildNodeOfNodeType (poNode, "SERIALIZEHIDDEN":U)) THEN
            eField.FieldSerializeHidden = TRUE .

    END METHOD .

    /*------------------------------------------------------------------------------
        Purpose: Event handler for the TempTableAstNodeAvailable event of the
                 TempTableAstWalker during the processing of selected temp-table names
        Notes:
        @param sender The object that raised the event
        @param e The TempTabelAstNodeAvailableEventArgs with the data for this event
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID ProcessTable (poNode AS JPNode, pcTableName AS CHARACTER):

        DEFINE VARIABLE oNode  AS JPNode  NO-UNDO .
        DEFINE VARIABLE iField AS INTEGER NO-UNDO.
        DEFINE VARIABLE iIndex AS INTEGER NO-UNDO.

        EMPTY TEMP-TABLE eField .

/*        CREATE eTable.                             */
/*        ASSIGN eTable.TempTableName = e:TableName .*/

        oNode = poNode:firstChild () .

        DO WHILE VALID-OBJECT (oNode):
            CASE NodeTypes:getTypeName (oNode:getType()):
                WHEN "FIELD":U THEN DO:
                    iField = iField + 1 .
                    ProcessFieldNode (oNode, pcTableName, iField) .
                END.
/*                WHEN "INDEX":U THEN DO:                            */
/*                    iIndex = iIndex + 1.                           */
/*                    ProcessIndexNode (oNode, e:TableName, iIndex) .*/
/*                END.                                               */

            END CASE .

            oNode = oNode:nextSibling () .
        END.

/*        ASSIGN iPositionOffset = iPositionOffset + 1 .                                      */
/*                                                                                            */
/*        oProcessedTables:Add (e:Controller:CreateTempTable (DATASET dsBusinessEntity:HANDLE,*/
/*                                                            e:Controller:Model,             */
/*                                                            iPositionOffset * 50,           */
/*                                                            iPositionOffset * 50,           */
/*                                                            FALSE,                          */
/*                                                            FALSE)) .                       */
    END METHOD .

    /**
     * Purpose:
     * Notes:
     *
     */
    METHOD PUBLIC VOID getTable (OUTPUT TABLE eField):
        /* noop */
    END METHOD.

    /*------------------------------------------------------------------------------
        Purpose: Returns the value of a FIELD attribute
        Notes:
        @param poNode The JPNode of the FIELD
        @param pcAttributeName The Name of the Attribute (Node Type)
        @return The attribute value (CHARACTER)
    ------------------------------------------------------------------------------*/
    METHOD PROTECTED CHARACTER GetFieldAttributeValue (poNode AS JPNode,
                                                       pcAttributeName AS CHARACTER):

        DEFINE VARIABLE cValue         AS CHARACTER NO-UNDO .
        DEFINE VARIABLE oAttributeNode AS JPNode    NO-UNDO .
        DEFINE VARIABLE iIndex         AS INTEGER   NO-UNDO .

        oAttributeNode = ProparseHelper:FindChildNodeOfNodeType (poNode, pcAttributeName) .

        IF NOT VALID-OBJECT (oAttributeNode) OR NOT VALID-OBJECT (oAttributeNode:firstChild()) THEN
            RETURN ? .

        ASSIGN cValue = TRIM(oAttributeNode:firstChild():getText ()) .

        IF cValue BEGINS "~"":U THEN DO:
            iIndex = R-INDEX (cValue, "~"":U) .

            IF iIndex > 2 THEN
                cValue = SUBSTRING (cValue, 2, iIndex - 2, "CHARACTER":U) .
        END.
        ELSE IF cValue BEGINS "'":U THEN DO:
            iIndex = R-INDEX (cValue, "'":U) .

            IF iIndex > 2 THEN
                cValue = SUBSTRING (cValue, 2, iIndex - 2, "CHARACTER":U) .
        END.

        RETURN cValue.

    END METHOD .



END CLASS.