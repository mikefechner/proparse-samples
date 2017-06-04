# proparse-samples
Samples from the Proparse presentation at PUG Challenge Americas 2017

The following procedures demonstrate the use of proparse:

* [a parse-simple-3.p](parse-simple-3.p): This procedure parses [a simple-3.p](simple-3.p) and creates a text output in [a simple-3.txt](simple-3.txt)
* [a parse-customer-tt.p](parse-customer-tt.p): This procedure parses [a customer-tt.p](customer-tt.p) and creates a text output in [a customer-tt.txt](customer-tt.txt). Main difference here, is that in ProcessAst (the recursive node-walker), the defaults of nodes of type [a org.prorefactor.nodetypes.RecordNameNode](http://www.joanju.com/analyst/javadoc/index.html?http://www.joanju.com/analyst/javadoc/org/prorefactor/nodetypes/RecordNameNode.html) are written to the output file. 
* [a parse-temp-table-sample.p](parse-temp-table-sample.p): This proceduce parses [a temp-table-sample.p](temp-table-sample.p) using the class [a Consultingwerk.Samples.TempTableParser.TempTableParser](Consultingwerk/Samples/TempTableParser/TempTableParser.cls). The details about the fields of the temp-table ttCustomer are written to the XML file [a ttCustomer.xml](ttCustomer.xml). 
