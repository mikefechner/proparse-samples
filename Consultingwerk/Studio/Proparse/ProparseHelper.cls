/**********************************************************************
 * Copyright (C) 2006-2013 by Consultingwerk Ltd. ("CW") -            *
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
    File        : ProparseHelper
    Purpose     : Provides advanced routines to analyse the Proparse AST
    Syntax      :
    Description :
    Author(s)   : Mike Fechner / Consultingwerk Ltd.
    Created     : Tue Jun 28 20:14:06 CEST 2011
    Notes       : http://www.joanju.com/analyst/javadoc/
  ----------------------------------------------------------------------*/

ROUTINE-LEVEL ON ERROR UNDO, THROW.

{Consultingwerk/products.i}

USING com.joanju.proparse.NodeTypes              FROM ASSEMBLY .
USING Consultingwerk.*                           FROM PROPATH .
USING Consultingwerk.Studio.Proparse.*           FROM PROPATH .
USING org.prorefactor.core.JPNode                FROM ASSEMBLY .
USING org.prorefactor.nodetypes.*                FROM ASSEMBLY .
USING org.prorefactor.treeparser.*               FROM ASSEMBLY .
USING Progress.Lang.*                            FROM PROPATH .

CLASS Consultingwerk.Studio.Proparse.ProparseHelper:

&IF DEFINED (DotNetAccessible) NE 0 &THEN
    DEFINE PRIVATE STATIC VARIABLE proparseEnv AS com.joanju.proparse.Environment NO-UNDO.
    DEFINE PRIVATE STATIC VARIABLE proparseSchema AS org.prorefactor.core.schema.Schema NO-UNDO.

    DEFINE PRIVATE STATIC VARIABLE prsession AS org.prorefactor.refactor.RefactorSession NO-UNDO .

    DEFINE PRIVATE STATIC VARIABLE oBackward AS org.proparse.api.Backward NO-UNDO.

    DEFINE PRIVATE STATIC VARIABLE lEnvironment  AS LOGICAL NO-UNDO INITIAL FALSE .
    DEFINE PRIVATE STATIC VARIABLE lInitalized   AS LOGICAL NO-UNDO INITIAL FALSE .

    /* To verify if ExportDatabaseSchema needs to reimport the schema */
    DEFINE PRIVATE STATIC VARIABLE cDbNamesSignature AS CHARACTER NO-UNDO INITIAL ? .

    {Consultingwerk/Studio/Proparse/ttRunStatements.i STATIC}

    /**
     * Purpose: Disallow instance creation
     * Notes:
     */
    CONSTRUCTOR PRIVATE ProparseHelper ():
        SUPER ().

    END CONSTRUCTOR.

    /**
     * Purpose: Static Constructor of the ProparseHelper class
     * Notes:
     */
    CONSTRUCTOR STATIC ProparseHelper ():

        proparseEnv = com.joanju.proparse.Environment:instance().
        proparseSchema = org.prorefactor.core.schema.Schema:getInstance().

        oBackward = NEW org.proparse.api.Backward().

    END CONSTRUCTOR.

    /**
     * Purpose: Searches for a child node of the given node with the matching node type
     * Notes:   This method does not work recursively, so only direct child nodes are
     *          processed
     * @param poASTNode The parent JPNode
     * @param pcChildNodeType The searched child not type as returned by NodeTypes:getTypeName
     * @return The found JPNode or the unknown value
     */
    METHOD PUBLIC STATIC JPNode FindChildNodeOfNodeType (poASTNode AS JPNode,
                                                         pcChildNodeType AS CHARACTER):

        DEFINE VARIABLE oChild      AS JPNode NO-UNDO .

        ASSIGN oChild = poASTNode:firstChild () .

        DO WHILE VALID-OBJECT (oChild):

            IF NodeTypes:getTypeName(oChild:getType()) = pcChildNodeType THEN
                RETURN oChild .

            oChild = oChild:nextSibling () .
        END.

        RETURN ? .

    END METHOD.

    /**
     * Purpose: Searches for a child node of the given node with the matching node type
     *          and text
     * Notes:   This method does not work recursively, so only direct child nodes are
     *          processed
     *          Useful for finding Annotations with getText() = "@Annotation"
     * @param poASTNode The parent JPNode
     * @param pcChildNodeType The searched child node type as returned by NodeTypes:getTypeName
     * @param pcChildNodeText The searched child node getText() value
     * @return The found JPNode or the unknown value
     */
    METHOD PUBLIC STATIC JPNode FindChildNodeOfNodeTypeWithText (poASTNode AS JPNode,
                                                                 pcChildNodeType AS CHARACTER,
                                                                 pcChildNodeText AS CHARACTER):

        DEFINE VARIABLE oChild      AS JPNode NO-UNDO .

        ASSIGN oChild = poASTNode:firstChild () .

        DO WHILE VALID-OBJECT (oChild):

            IF NodeTypes:getTypeName(oChild:getType()) = pcChildNodeType AND
               oChild:getText()                        = pcChildNodeText THEN
                RETURN oChild .

            oChild = oChild:nextSibling () .
        END.

        RETURN ? .

    END METHOD.

    /**
     * Purpose: Searches for a child node of the given node with the matching node type
     *          and ID childnode text
     * Notes:   This method does not work recursively, so only direct child nodes are
     *          processed
     *          Useful for finding
     * @param poASTNode The parent JPNode
     * @param pcChildNodeType The searched child node type as returned by NodeTypes:getTypeName
     * @param pcChildNodeID The searched child node ID node value
     * @return The found JPNode or the unknown value
     */
    METHOD PUBLIC STATIC JPNode FindChildNodeOfNodeTypeWithID (poASTNode AS JPNode,
                                                               pcChildNodeType AS CHARACTER,
                                                               pcChildNodeID AS CHARACTER):

        DEFINE VARIABLE oChild      AS JPNode NO-UNDO .

        ASSIGN oChild = poASTNode:firstChild () .

        DO WHILE VALID-OBJECT (oChild):

            IF NodeTypes:getTypeName(oChild:getType()) = pcChildNodeType AND
               ProparseHelper:HasChildNodeOfNodeTypeWithText (oChild,
                                                              "ID":U,
                                                              pcChildNodeID) THEN
                RETURN oChild .

            oChild = oChild:nextSibling () .
        END.

        RETURN ? .

    END METHOD.

    /**
     * Purpose: Returns the first JPNode in a AST by position
     * Notes:
     * @param poNode The parent JPNode
     * @return The found JPNode or the unknown value
     */
    METHOD PUBLIC STATIC JPNode FindFirstChildByPositionInCode (poNode AS JPNode):

        DEFINE VARIABLE oFirstNode AS JPNode                                      NO-UNDO .
        DEFINE VARIABLE oNodes     AS "System.Collections.Generic.List<JPNode>":U NO-UNDO .

        oNodes = NEW "System.Collections.Generic.List<JPNode>" () .

        ProparseHelper:GetNodeChildren (poNode, oNodes) .

        {Consultingwerk/foreach.i JPNode oNode in oNodes}
            IF NOT VALID-OBJECT (oFirstNode) THEN DO:

                IF oNode:getLine() > 0 AND oNode:getColumn() > 0 THEN
                    oFirstNode = oNode .
            END.
            ELSE
                IF oNode:getLine() > 0 AND oNode:getColumn() > 0 AND
                   (oNode:getLine() < oFirstNode:getLine() OR
                   (oNode:getLine() = oFirstNode:getLine() AND oNode:getColumn() < oFirstNode:getColumn())) THEN
                   oFirstNode = oNode .
        END. /* foreach.i */

        RETURN oFirstNode .

    END METHOD.

    /**
     * Purpose: Returns the List with all children (direct and indirect added)
     * Notes:
     * @param poNode The parent JPNode
     * @param poNodes The generic List of JPNode object
     */
    METHOD PUBLIC STATIC VOID GetNodeChildren (poNode AS JPNode,
                                               poNodes AS "System.Collections.Generic.List<JPNode>":U):

        DEFINE VARIABLE oNode AS JPNode NO-UNDO .

        Consultingwerk.Assertion.ObjectAssert:IsValid (poNode, "Parent Node":U) .
        Consultingwerk.Assertion.ObjectAssert:IsValid (poNode, "Nodes List":U) .

        ASSIGN oNode = poNode:firstChild () .

        DO WHILE VALID-OBJECT (oNode):
            poNodes:Add (oNode) .

            IF VALID-OBJECT (oNode:firstChild()) THEN
                GetNodeChildren (oNode, poNodes) .

            oNode = oNode:nextSibling () .
        END.

    END METHOD.

    /**
     * Purpose: Returns the List with all children of the given node type
     *          (direct and indirect added)
     * Notes:
     * @param poNode The parent JPNode
     * @param pcNodeType The node type to add
     * @param poNodes The generic List of JPNode object
     */
    METHOD PUBLIC STATIC VOID GetNodeChildrenOfNodeType (poNode AS JPNode,
                                                         pcNodeType AS CHARACTER,
                                                         poNodes AS "System.Collections.Generic.List<JPNode>":U):

        DEFINE VARIABLE oNode AS JPNode NO-UNDO .

        Consultingwerk.Assertion.ObjectAssert:IsValid (poNode, "Parent Node":U) .
        Consultingwerk.Assertion.ObjectAssert:IsValid (poNode, "Nodes List":U) .

        ASSIGN oNode = poNode:firstChild () .

        DO WHILE VALID-OBJECT (oNode):
            IF NodeTypes:getTypeName(oNode:getType()) = pcNodeType THEN
                poNodes:Add (oNode) .

            IF VALID-OBJECT (oNode:firstChild()) THEN
                GetNodeChildrenOfNodeType (oNode, pcNodeType, poNodes) .

            oNode = oNode:nextSibling () .
        END.

    END METHOD.

    /**
     * Purpose: Gets a Node by it's number
     * Notes:
     * @param piNodeNum The node number to return
     * @return The JPNode with the specified number
     */
    METHOD PUBLIC STATIC JPNode GetNodeFromNum (piNodeNum AS INTEGER):

        DEFINE VARIABLE node AS JPNode NO-UNDO.

        node = oBackward:getNode(piNodeNum).

        RETURN node.

    END METHOD.

    /**
     * Purpose: Returns the Subtype name based on Proparse's SubType Index
     * Notes:
     * @param piSubtypeIndex The index of the subtype as returns from the JPNode
     * @return The CHARACTER SubtypeName
     */
    METHOD PUBLIC STATIC CHARACTER GetSubtypeName (piSubtypeIndex AS INTEGER):

        DEFINE VARIABLE cSubtypes AS CHARACTER NO-UNDO EXTENT 6
            INITIAL ["JPNode":U,
                  "BlockNode":U,
                  "FieldRefNode":U,
                  "RecordNameNode":U,
                  "ProparseDirectiveNode":U,
                  "ProgramRootNode":U].

        IF piSubtypeIndex > EXTENT (cSubtypes) THEN
            UNDO, THROW NEW AppError (SUBSTITUTE ("Unknown subtype index &1"{&TRAN}, piSubtypeIndex), 0) .

        RETURN cSubtypes [piSubtypeIndex] .

    END METHOD.

    /**
     * Purpose: Searches for a Childnode of the given node with the matching node type
     * Notes:
     * @param poASTNode The parent JPNode
     * @param pcChildNodeType The searched child not type as returned by NodeTypes:getTypeName
     * @return True when a child node with the given node type exists
     */
    METHOD PUBLIC STATIC LOGICAL HasChildNodeOfNodeType (poASTNode AS JPNode,
                                                         pcChildNodeType AS CHARACTER):

        DEFINE VARIABLE oChild      AS JPNode NO-UNDO .

        ASSIGN oChild = poASTNode:firstChild () .

        DO WHILE VALID-OBJECT (oChild):

            IF NodeTypes:getTypeName(oChild:getType()) = pcChildNodeType THEN
                RETURN TRUE .

            oChild = oChild:nextSibling () .
        END.

        RETURN FALSE .

    END METHOD .

    /**
     * Purpose: Searches for a Childnode of the given node with the matching node type
     *          and text
     * Notes:   Useful for finding Annotations with getText() = "@Annotation"
     * @param poASTNode The parent JPNode
     * @param pcChildNodeType The searched child not type as returned by NodeTypes:getTypeName
     * @param pcChildNodeText The searched child node getText() value
     * @return True when a child node with the given node type exists
     */
    METHOD PUBLIC STATIC LOGICAL HasChildNodeOfNodeTypeWithText (poASTNode AS JPNode,
                                                                 pcChildNodeType AS CHARACTER,
                                                                 pcChildNodeText AS CHARACTER):

        DEFINE VARIABLE oChild      AS JPNode NO-UNDO .

        ASSIGN oChild = poASTNode:firstChild () .

        DO WHILE VALID-OBJECT (oChild):

            IF NodeTypes:getTypeName(oChild:getType()) = pcChildNodeType AND
               oChild:getText()                        = pcChildNodeText THEN

                RETURN TRUE .

            oChild = oChild:nextSibling () .
        END.

        RETURN FALSE .

    END METHOD .

    /**
     * Purpose: Searches for a Childnode of the given node with the matching node type
     *          and ID childnode text
     * Notes:   Useful for finding PROCEDURE with a certain name etc.
     * @param poASTNode The parent JPNode
     * @param pcChildNodeType The searched child not type as returned by NodeTypes:getTypeName
     * @param pcChildNodeID The searched child node ID node value
     * @return True when a child node with the given node type exists
     */
    METHOD PUBLIC STATIC LOGICAL HasChildNodeOfNodeTypeWithID (poASTNode AS JPNode,
                                                               pcChildNodeType AS CHARACTER,
                                                               pcChildNodeID AS CHARACTER):

        DEFINE VARIABLE oChild      AS JPNode NO-UNDO .

        ASSIGN oChild = poASTNode:firstChild () .

        DO WHILE VALID-OBJECT (oChild):

            IF NodeTypes:getTypeName(oChild:getType()) = pcChildNodeType AND
               ProparseHelper:HasChildNodeOfNodeTypeWithText (oChild,
                                                              "ID":U,
                                                              pcChildNodeID) THEN
                    RETURN TRUE .

            oChild = oChild:nextSibling () .
        END.

        RETURN FALSE .

    END METHOD .

    /**
     * Purpose: Initializes propase
     * Notes:
     */
    METHOD PUBLIC STATIC VOID Initialize ():

        org.prorefactor.refactor.RefactorSession:invalidateCurrentSettings () .

        prsession = org.prorefactor.refactor.RefactorSession:getInstance().
        prsession:setContextDirName (SESSION:TEMP-DIRECTORY) .

        oBackward:clear().

        ASSIGN lInitalized = TRUE .

    END METHOD.

    /**
     * Purpose: Finds the Routine-Level Block that contains the given JPNode
     * Notes:
     * @param poNode The JPNode to return the reference to the routine-level block for
     * @return The JPNode that describes the routine-level block for the given JPNode
     */
    METHOD PUBLIC STATIC JPNode FindRoutineParent (poNode AS JPNode):

        DEFINE VARIABLE oParent AS JPNode NO-UNDO.

        oParent = poNode:parent () .

        DO WHILE VALID-OBJECT (oParent):

            IF LOOKUP (NodeTypes:getTypeName(oParent:getType()),
                      "ON,PROCEDURE,FUNCTION,METHOD,Program_root,CLASS,CONSTRUCTOR,METHOD,GET,SET":U) > 0 THEN

                RETURN oParent .

            oParent = oParent:parent () .
        END.

        RETURN ? .

    END METHOD.

    /**
     * Purpose: Returns the block level relative to the next Routine-Level Block
     *          for the given JPNode
     * Notes:
     * @param poNode The JPNode to return the block level for
     * @return Block level relatively to the parent node
     */
    METHOD PUBLIC STATIC INTEGER GetRoutineDepth (poNode AS JPNode):

        DEFINE VARIABLE oParent AS JPNode  NO-UNDO.
        DEFINE VARIABLE iDepth  AS INTEGER NO-UNDO.

        oParent = poNode:parent () .


        DO WHILE VALID-OBJECT (oParent):

            IF LOOKUP (NodeTypes:getTypeName(oParent:getType()),
                      "ON,PROCEDURE,FUNCTION,METHOD,CLASS,CONSTRUCTOR,METHOD,GET,SET":U) > 0 THEN

                RETURN iDepth .

            IF NodeTypes:getTypeName(oParent:getType()) = "Code_block":U THEN
                ASSIGN iDepth = iDepth + 1.

            oParent = oParent:parent () .
        END.

        RETURN ? .

    END METHOD.

    /**
     * Purpose: Returns if the parent of the given JPNode is a simple DO: block
     *          (without any condision, e.g. DO WITH FRAME:)
     * Notes:
     * @param poNode The JPNode to test the parent block of
     * @return Logical value indicating if the parent of the given node is a trivial DO block
     */
    METHOD PUBLIC STATIC LOGICAL ParentIsTrivialDo (poNode AS JPNode):

        DEFINE VARIABLE oParent AS JPNode  NO-UNDO.

        oParent = poNode:parent () .

        IF NodeTypes:getTypeName(oParent:getType()) = "Code_block":U AND
           NodeTypes:getTypeName(oParent:parent():getType()) = "DO":U AND
           NodeTypes:getTypeName(oParent:parent():parent():getType()) = "Code_block":U THEN

            RETURN TRUE .

        ELSE
            RETURN FALSE .
    END METHOD .

    /**
     * Purpose: Returns the number of child nodes of the given node with the matching
     *          node type
     * Notes:   This method does not work recursively, so only direct child nodes are
     *          counted
     * @param poASTNode The parent JPNode
     * @param pcChildNodeType The searched child not type as returned by NodeTypes:getTypeName
     * @return The number of child nodes with the given type
     */
    METHOD PUBLIC STATIC INTEGER NumChildNodeOfNodeType (poASTNode AS JPNode,
                                                         pcChildNodeType AS CHARACTER):

        DEFINE VARIABLE oChild AS JPNode  NO-UNDO .
        DEFINE VARIABLE iCount AS INTEGER NO-UNDO .

        ASSIGN oChild = poASTNode:firstChild () .

        DO WHILE VALID-OBJECT (oChild):

            IF NodeTypes:getTypeName(oChild:getType()) = pcChildNodeType THEN
                ASSIGN iCount = iCount + 1 .

            oChild = oChild:nextSibling () .
        END.

        RETURN iCount .

    END METHOD .

    /**
     * Purpose: Returns the number of direct child nodes of the given JPNode
     * Notes:
     * @param poNode The JPNode to return the number of children of
     * @return The number of direct child nods
     */
    METHOD PUBLIC STATIC INTEGER NumChildren (poNode AS JPNode):

        {Consultingwerk/Assertion/ObjectAssert/IsValid.i poNode "'poNode':U"}

        RETURN poNode:getDirectChildren():size() .

    END METHOD .

    /**
     * Purpose: Returns a parser configuration parameter
     * Notes:
     * @param pcFlag The name of a proparse config flag
     * @return The CHARACTER value of the Proparse config value
     */
    METHOD PUBLIC STATIC CHARACTER ParserConfigGet (pcFlag AS CHARACTER):

       RETURN proparseEnv:configGet (pcFlag).

    END METHOD.

    /**
     * Purpose: Sets a proparse configuration parameter (propath, proversion)
     * Notes:
     * @param pcFlag The name of a proparse config flag
     * @param pcValue The value for the proparse config flag
     * @return Always TRUE
     */
    METHOD PUBLIC STATIC LOGICAL ParserConfigSet (pcFlag AS CHARACTER, pcValue AS CHARACTER):

          proparseEnv:configSet (pcFlag, pcValue).

          RETURN TRUE.

    END METHOD.

    /**
     * Purpose: Set's OpenEdge session enviroment in proparse
     * Notes:
     */
    METHOD PUBLIC STATIC VOID SetProparseEnvironment ():

        ParserConfigSet ("batch-mode":U, STRING(SESSION:BATCH-MODE, "true/false":U)).
        ParserConfigSet ("opsys":U, OPSYS).
        ParserConfigSet ("propath":U, PROPATH).
        ParserConfigSet ("proversion":U, PROVERSION).
        ParserConfigSet ("window-system":U, SESSION:WINDOW-SYSTEM).

        ASSIGN lEnvironment = TRUE .

    END METHOD.

    /**
     * Purpose: Returns the Text of the Event_list node of a Trigger node
     * Notes:   Returns "":U if no Event_list node is present
     * @param poASTNode The JPNode of the Trigger itself (ON / Blocknode)
     * @return The Text of the Event_list node
     */
    METHOD PUBLIC STATIC CHARACTER TriggerEventList (poASTNode AS JPNode):

        DEFINE VARIABLE oChild      AS JPNode NO-UNDO .
        DEFINE VARIABLE oGrandChild AS JPNode NO-UNDO .

        ASSIGN oChild = poASTNode:firstChild () .

        DO WHILE VALID-OBJECT (oChild):

            IF NodeTypes:getTypeName(oChild:getType()) = "Event_List":U THEN DO:
                oGrandChild = oChild:firstChild () .

                RETURN oGrandChild:getText () .
            END.

            oChild = oChild:nextSibling () .
        END.

        RETURN "":U .

    END METHOD.

    /**
     * Purpose: Returns the complete trigger Event_list node of a Trigger node
     * Notes:   Returns "":U if no Event_list node is present, comma-delimited
     * @param poASTNode The JPNode of the Trigger itself (ON / Blocknode)
     * @return The Text of the Event_list node
     */
    METHOD PUBLIC STATIC CHARACTER TriggerCompleteEventList (poASTNode AS JPNode):

        DEFINE VARIABLE oChild      AS JPNode NO-UNDO .
        DEFINE VARIABLE oGrandChild AS JPNode NO-UNDO .

        DEFINE VARIABLE cReturn AS CHARACTER NO-UNDO.

        ASSIGN oChild = poASTNode:firstChild () .

        DO WHILE VALID-OBJECT (oChild):

            IF NodeTypes:getTypeName(oChild:getType()) = "Event_List":U THEN DO:
                oGrandChild = oChild:firstChild () .

                DO WHILE VALID-OBJECT (oGrandChild):
                    IF NodeTypes:getTypeName(oGrandChild:getType()) <> "COMMA":U THEN

                        ASSIGN cReturn = cReturn + ",":U + oGrandChild:getText () .

                    ASSIGN oGrandChild = oGrandChild:nextSibling () .
                END.
            END.

            oChild = oChild:nextSibling () .
        END.

        RETURN TRIM (cReturn, ",":U) .

    END METHOD.

    /**
     * Purpose: Returns the Text of the Widget_ref node of a Trigger node
     * Notes:   Returns "":U if no Widget_ref node is present, drills down into the
     *          Field_ref node if present (for UI widgets)
     * @param poASTNode The JPNode of the Trigger itself (ON / Blocknode)
     * @return The Text of the Widget_ref node
     */
    METHOD PUBLIC STATIC CHARACTER TriggerWidgetRef (poASTNode AS JPNode):

        DEFINE VARIABLE oChild       AS JPNode NO-UNDO .
        DEFINE VARIABLE oGrandChild  AS JPNode NO-UNDO .
        DEFINE VARIABLE oGrandChild2 AS JPNode NO-UNDO .

        ASSIGN oChild = poASTNode:firstChild () .

        DO WHILE VALID-OBJECT (oChild):

            IF NodeTypes:getTypeName(oChild:getType()) = "Widget_ref":U THEN DO:
                oGrandChild = oChild:firstChild () .

                IF NodeTypes:getTypeName(oGrandChild:getType()) = "Field_ref":U THEN DO:
                    oGrandChild2 = oGrandChild:firstChild () .

                    RETURN oGrandChild2:getText () .
                END.
                ELSE
                    RETURN oGrandChild:getText () .
            END.

            oChild = oChild:nextSibling () .
        END.

        RETURN "":U .

    END METHOD.
&ENDIF
END CLASS.
