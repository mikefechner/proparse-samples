/*------------------------------------------------------------------------
    File        : parse-temp-table-sample.p
    Purpose     :

    Syntax      :

    Description :

    Author(s)   :
    Created     : Sun Jun 04 21:48:54 CEST 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Consultingwerk.Samples.TempTableParser.* FROM PROPATH .
USING Consultingwerk.Studio.Proparse.*         FROM PROPATH .
USING com.joanju.proparse.NodeTypes            FROM ASSEMBLY .
USING org.prorefactor.core.JPNode              FROM ASSEMBLY .
USING org.prorefactor.nodetypes.*              FROM ASSEMBLY .
USING org.prorefactor.treeparser.*             FROM ASSEMBLY .
USING Progress.Lang.*                          FROM PROPATH .

DEFINE VARIABLE proparseEnv    AS com.joanju.proparse.Environment          NO-UNDO .
DEFINE VARIABLE proparseSchema AS org.prorefactor.core.schema.Schema       NO-UNDO .
DEFINE VARIABLE prsession      AS org.prorefactor.refactor.RefactorSession NO-UNDO .

DEFINE VARIABLE javafile       AS java.io.File                             NO-UNDO .
DEFINE VARIABLE pu             AS org.prorefactor.treeparser.ParseUnit     NO-UNDO .

DEFINE VARIABLE oNode          AS JPNode                                   NO-UNDO .
DEFINE VARIABLE cTempTableName AS CHARACTER                                NO-UNDO .
DEFINE VARIABLE oParser        AS TempTableParser                          NO-UNDO .

{ Consultingwerk/BusinessEntityDesigner/Services/eField.i }

/* ***************************  Main Block  *************************** */

RUN ExportSessionSettings .
RUN ExportDatabaseSchema .
RUN InitializeParserSession .

/* Parse ABL source code */
javafile = NEW java.io.File ("temp-table-sample.p").

IF (NOT javafile:exists()) THEN
    UNDO, THROW NEW AppError (SUBSTITUTE ("Could not find file: &1.", "simple-3.p"), 0) .

pu = NEW ParseUnit(javafile).
/* Invoke the actual parser */
pu:treeParser01().

DELETE OBJECT javafile .

ASSIGN oNode = pu:getTopNode():firstChild() .

/* Assuming, the temp-table is not falsely defined inside a block */
DO WHILE VALID-OBJECT (oNode):
    IF NodeTypes:getTypeName(oNode:getType()) = "DEFINE" AND
       ProparseHelper:HasChildNodeOfNodeType(oNode, "TEMPTABLE") THEN DO:

        ASSIGN cTempTableName = ProparseHelper:FindChildNodeOfNodeType(oNode, "ID"):getText ().

        oParser = NEW TempTableParser() .

        oParser:ProcessTable(oNode, cTempTableName) .
        oParser:GetTable (OUTPUT TABLE eField) .

        TEMP-TABLE eField:WRITE-XML ("file",
                                     SUBSTITUTE ("&1.xml", cTempTableName),
                                     YES, ?, ?) .
    END.

    oNode = oNode:nextSibling () .
END.

CATCH err AS Progress.Lang.Error:
    MESSAGE err:GetMessage(1) SKIP
            err:CallStack
        VIEW-AS ALERT-BOX ERROR TITLE "Error".
END CATCH.

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
