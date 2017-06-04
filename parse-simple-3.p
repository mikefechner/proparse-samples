/*------------------------------------------------------------------------
    File        : parse-simple-3.p
    Purpose     :

    Syntax      :

    Description :

    Author(s)   :
    Created     : Sun Jun 04 18:11:09 CEST 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

BLOCK-LEVEL ON ERROR UNDO, THROW.

USING com.joanju.proparse.NodeTypes FROM ASSEMBLY .
USING org.prorefactor.core.JPNode   FROM ASSEMBLY .
USING org.prorefactor.nodetypes.*   FROM ASSEMBLY .
USING org.prorefactor.treeparser.*  FROM ASSEMBLY .
USING Progress.Lang.*               FROM PROPATH .

DEFINE VARIABLE proparseEnv    AS com.joanju.proparse.Environment          NO-UNDO .
DEFINE VARIABLE proparseSchema AS org.prorefactor.core.schema.Schema       NO-UNDO .
DEFINE VARIABLE prsession      AS org.prorefactor.refactor.RefactorSession NO-UNDO .

DEFINE VARIABLE javafile       AS java.io.File                             NO-UNDO .
DEFINE VARIABLE pu             AS org.prorefactor.treeparser.ParseUnit     NO-UNDO .

/* ***************************  Main Block  *************************** */

RUN ExportSessionSettings .
RUN ExportDatabaseSchema .
RUN InitializeParserSession .

/* Parse ABL source code */
javafile = NEW java.io.File ("simple-3.p").

IF (NOT javafile:exists()) THEN
    UNDO, THROW NEW AppError (SUBSTITUTE ("Could not find file: &1.", "simple-3.p"), 0) .

pu = NEW ParseUnit(javafile).
/* Invoke the actual parser */
pu:treeParser01().

DELETE OBJECT javafile .

OUTPUT TO simple-3.txt .
PUT UNFORMATTED "org.prorefactor.nodetypes....  | getType()           |getSubTypeIndex()| getText ()          | ToString ()" SKIP .
PUT UNFORMATTED "-------------------------------|---------------------|-----------------|---------------------|--------------------------------------------" SKIP .


RUN ProcessAst (pu:getTopNode(), 0) .

CATCH err AS Progress.Lang.Error:
    MESSAGE err:GetMessage(1) SKIP
            err:CallStack
        VIEW-AS ALERT-BOX ERROR TITLE "Error".
END CATCH.

FINALLY:
    OUTPUT CLOSE .
END FINALLY.

/**
 * Purpose: Exports the ABL Session Settings
 * Notes:
 */
PROCEDURE ExportSessionSettings:

    proparseEnv = com.joanju.proparse.Environment:instance().
    /* Export ABL Session settings to Proparse */

    proparseEnv:configSet ("batch-mode":U, STRING(SESSION:BATCH-MODE, "true/false":U)).
    proparseEnv:configSet ("opsys":U, OPSYS).
    proparseEnv:configSet ("propath":U, PROPATH).
    proparseEnv:configSet ("proversion":U, PROVERSION).
    proparseEnv:configSet ("window-system":U, SESSION:WINDOW-SYSTEM).

END PROCEDURE .

/**
 * Purpose: Exports the Database Schema to Proparse
 * Notes:   Will only export the database schema to proparse when there are new
 *          databases connected or new aliases defined
 */
PROCEDURE ExportDatabaseSchema:

    DEFINE VARIABLE iAlias                   AS INTEGER        NO-UNDO .
    DEFINE VARIABLE schemaDumpFile           AS CHARACTER      NO-UNDO .

    proparseSchema = org.prorefactor.core.schema.Schema:getInstance().

    proparseSchema:clear().

    IF NUM-DBS > 0 THEN DO:
        schemaDumpFile = Consultingwerk.Util.FileHelper:GetTempFileName() .

        RUN Consultingwerk/Studio/Proparse/schemadump1.p (schemaDumpFile).

        proparseSchema:loadSchema(schemaDumpFile).

        DO iAlias = 1 TO NUM-ALIASES:
            proparseSchema:aliasCreate (ALIAS (iAlias), LDBNAME (ALIAS (iAlias))) .
        END.
    END.

    FINALLY:
        OS-DELETE VALUE (schemaDumpFile) .
    END FINALLY.

END PROCEDURE .

/**
 * Purpose: Initializes the Propase Session
 * Notes:
 */
PROCEDURE InitializeParserSession:

    org.prorefactor.refactor.RefactorSession:invalidateCurrentSettings () .

    prsession = org.prorefactor.refactor.RefactorSession:getInstance().
    prsession:setContextDirName (SESSION:TEMP-DIRECTORY) .

END PROCEDURE.

/**
 * Purpose: Initializes the Propase Session
 * Notes:
 */
PROCEDURE ProcessAst:

    DEFINE INPUT PARAMETER poNode    AS JPNode  NO-UNDO .
    DEFINE INPUT PARAMETER piNesting AS INTEGER NO-UNDO .

    DEFINE VARIABLE cNodeType AS CHARACTER NO-UNDO .
    DEFINE VARIABLE oChild    AS JPNode    NO-UNDO .

    DEFINE VARIABLE cSubtypes AS CHARACTER NO-UNDO
        INIT "JPNode,BlockNode,FieldRefNode,RecordNameNode,ProparseDirectiveNode,ProgramRootNode":U .

    ASSIGN cNodeType = CAST (poNode, System.Object):GetType():FullName
           cNodeType = ENTRY (NUM-ENTRIES (cNodeType, "."), cNodeType, ".").

    PUT UNFORMATTED FILL (" ", piNesting * 2)
                    cNodeType " "
                    FILL (" ", 30 - piNesting * 2 - LENGTH (cNodeType))           "| "
                    STRING (NodeTypes:getTypeName(poNode:getType()),     "x(20)") "| "
                    STRING (ENTRY (poNode:getSubTypeIndex(), cSubtypes), "x(16)") "| "
                    STRING (poNode:getText(),                            "x(20)") "| "
                    poNode:ToString()
                    SKIP .

    ASSIGN oChild = poNode:firstChild () .

    DO WHILE VALID-OBJECT (oChild):
        RUN ProcessAst (oChild, piNesting + 1) .


        oChild = oChild:nextSibling () .
    END.

END PROCEDURE .
