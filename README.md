# proparse-samples
Samples from the Proparse presentation at PUG Challenge Americas 2017

The following procedures demonstrate the use of proparse:

* [parse-simple-3.p](parse-simple-3.p): This procedure parses [simple-3.p](simple-3.p) and creates a text output in [simple-3.txt](simple-3.txt)
* [parse-customer-tt.p](parse-customer-tt.p): This procedure parses [customer-tt.p](customer-tt.p) and creates a text output in [customer-tt.txt](customer-tt.txt). Main difference here, is that in ProcessAst (the recursive node-walker), the defaults of nodes of type [org.prorefactor.nodetypes.RecordNameNode](http://www.joanju.com/analyst/javadoc/index.html?http://www.joanju.com/analyst/javadoc/org/prorefactor/nodetypes/RecordNameNode.html) are written to the output file. 
* [parse-temp-table-sample.p](parse-temp-table-sample.p): This proceduce parses [temp-table-sample.p](temp-table-sample.p) using the class [Consultingwerk.Samples.TempTableParser.TempTableParser](Consultingwerk/Samples/TempTableParser/TempTableParser.cls). The details about the fields of the temp-table ttCustomer are written to the XML file [ttCustomer.xml](ttCustomer.xml). 
