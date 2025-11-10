# Create output simulation time string form output schema in json format

Create output simulation time string form output schema in json format

## Usage

``` r
.createOutputSchemaStringFromJson(outputSchemaJson, schemaUnit = NULL)
```

## Arguments

- outputSchemaJson:

  The 'OutputSchema' section from a Simulation of a json

- schemaUnit:

  The unit of the start time of the first interval PK-Sim snapshot

## Value

A named list, with 'Intervals' a string where each output interval is
defined as \<start, end, resolution\>, and intervals are separated by a
';', and 'Unit' the unit of the start time of the first interval. All
values are transformed to 'Unit'.
