#! bash
export PODNAME=$(oc get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep 'mysql')

oc cp ./create_database_quotesdb.sql $PODNAME:/tmp/create_database_quotesdb.sql
oc cp ./create_database.sh $PODNAME:/tmp/create_database.sh
oc exec "$PODNAME" -- /bin/bash ./tmp/create_database.sh

oc cp ./create_table_quotes.sql $PODNAME:/tmp/create_table_quotes.sql
oc cp ./create_tables.sh $PODNAME:/tmp/create_tables.sh
oc exec "$PODNAME" -- /bin/bash ./tmp/create_tables.sh

oc cp ./populate_table_quotes_BASH.sql $PODNAME:/tmp/populate_table_quotes_BASH.sql
oc cp ./quotes.csv $PODNAME:/tmp/quotes.csv
oc cp ./populate_tables_BASH.sh $PODNAME:/tmp/populate_tables_BASH.sh
oc exec "$PODNAME" -- /bin/bash ./tmp/populate_tables_BASH.sh

oc cp ./query_table_quotes.sql $PODNAME:/tmp/query_table_quotes.sql
oc cp ./query_table_quotes.sh $PODNAME:/tmp/query_table_quotes.sh
oc exec "$PODNAME" -- /bin/bash ./tmp/query_table_quotes.sh