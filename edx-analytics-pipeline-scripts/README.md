Overview
--------

This repository contains SQL scripts that are run on the data warehouse (vertica) daily. They are executed in order after the `production` schema has been updated by the data pipeline. The order is specified by the `config.yml` file that is expected to be found at the root of this repository.

Runtime Environment
-------------------

The contents of this repository are checked out and executed by the data pipeline with the search path set to "business\_intelligence". Any tables that are missing explicit schema references will reference tables in the business\_intelligence schema. The pipeline executes these scripts as the `business-intelligence-etl` user. If a script fails, none of the scripts that follow it will be run. Each script can assume that all previously scheduled scripts have executed successfully. Each script is executed in a different transaction. Scripts should contain all statements needed to generate a fully functional table, including schema definition, data loading and definition of projections.

Conventions
-----------

Manage a single table with each script. Note that you can either drop and re-create the table, append data to the table (this should be idempotent), or create a view.

config.yml
----------

This configuration file must contain a `scripts` key that references an array of mappings. Each mapping contains metadata for the scripts that are executed by the data pipeline. Each mapping is required to contain a `location` key which defines the relative path to the script from the root of this repository. It also must define a `name` key whose value is used to refer to the script in a more concise way. Each mapping may also define a `description` key whose value should be a human readable description of what the table is and each row represents. This information is not currently surfaced elsewhere, but we intend to do so in the future.
